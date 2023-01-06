#Libraries
library(tidyverse)
library(gganimate)
library(cowplot)
library(repr)
library(nflfastR)
library(nflreadr)
library(ggplot2)
library(ggpubr)
library(nnet)

#Global Settings
options(warn=-1)
options(repr.plot.width=15, repr.plot.height = 10)

#Non-Tracking Data Load
playsDF <- read.csv("C:\\Users\\josep\\Dropbox\\joe\\Big Data Bowl\\nfl-big-data-bowl-2023\\plays.csv")
playersDF <- read.csv("C:\\Users\\josep\\Dropbox\\joe\\Big Data Bowl\\nfl-big-data-bowl-2023\\players.csv")
pffDF <- read.csv("C:\\Users\\josep\\Dropbox\\joe\\Big Data Bowl\\nfl-big-data-bowl-2023\\pffScoutingData.csv")
readrPlaysDF <- read_csv("https://github.com/nflverse/nflverse-data/releases/download/pbp/play_by_play_2021.csv",col_types=cols_only(old_game_id='i', play_id ='i', xpass='d'))
nflrDF <- load_pbp(2021)

#Tracking Data Load
weeks <- seq(1, 8)
trackDF <- data.frame()
for (w in weeks) {
  tempTrackDF <- read.csv(paste0("C:\\Users\\josep\\Dropbox\\joe\\Big Data Bowl\\nfl-big-data-bowl-2023\\week",w, ".csv"))
  trackDF <- bind_rows(trackDF, tempTrackDF)
}
rm(tempTrackDF)

#Add in Counter Variable to 'playsDF', 'nflrDF', & 'pffDF'
playsDF["playCounter"] <- 1
nflrDF["playCounter"] <- 1
pffDF["playCounter"] <- 1

#Add in Names and Positions of Players
pffDF <- pffDF %>%
  left_join(playersDF, by = c("nflId" = "nflId"))
pffDF <- pffDF %>%
  left_join(playersDF, by = c("pff_nflIdBlockedPlayer" = "nflId"))

pffDF <- pffDF[, -c(17:20, 23:26)]
colnames(pffDF)[colnames(pffDF) == "officialPosition.x"] = "playerPos"
colnames(pffDF)[colnames(pffDF) == "displayName.x"] = "playerName"
colnames(pffDF)[colnames(pffDF) == "officialPosition.y"] = "oppPos"
colnames(pffDF)[colnames(pffDF) == "displayName.y"] = "oppName"

#Filter for Only Pass Blockers, Not Including RBs
passBlockDF <- pffDF %>%
  filter(pff_role == "Pass Block" & playerPos != "RB")

#Filter for Only Pass Rushers
passRushDF <- pffDF %>%
  filter(pff_role == "Pass Rush")

#Add in EPA for Each Play
nflrDF["gameId"] <- as.numeric(nflrDF$old_game_id)
passRushDF <- passRushDF %>%
  left_join(nflrDF[, c("play_id", "epa", "gameId")], 
            by = c("gameId" = "gameId", "playId" = "play_id"))

#Find Metric Totals for Pass Rushers
rushMetricsDF <- passRushDF %>%
  group_by(nflId, playerName, playerPos) %>%
  summarize(playTot = sum(playCounter),
            sackTot = sum(pff_sack, na.rm = TRUE),
            hitTot = sum(pff_hit, na.rm = TRUE),
            hurryTot = sum(pff_hurry, na.rm = TRUE),
            epaAvg = mean(-1 * epa))
rushMetricsDF <- rushMetricsDF[rushMetricsDF$playTot >= 50, ]

#Create a Linear Regression Model to Find Correlation Between
#Metrics and EPA
epaSackLM <- lm(epaAvg ~ sackTot , data = rushMetricsDF)
epaHitLM <- lm(epaAvg ~ hitTot, data = rushMetricsDF)
epaHurryLM <- lm(epaAvg ~ hurryTot, data = rushMetricsDF)

#Add in a "Success" Rating Using the Converted Linear Coefficients
#Made to Add Up to 1
rushMetricsDF["actSuccessRate"] <- (rushMetricsDF$sackTot*0.6 + 
                                   rushMetricsDF$hitTot*0.2667 +
                                   rushMetricsDF$hurryTot*0.1333)
rushMetricsDF["actSuccessAvg"] <- round(rushMetricsDF$actSuccessRate / rushMetricsDF$playTot, 4)


#Find Out Double Team Plays
doubleTeamDF <- passBlockDF %>%
  group_by(pff_nflIdBlockedPlayer, oppName, oppPos) %>%
  summarize(blockerTot = sum(playCounter))

#Create Blockers Per Rusher
rushMetricsDF <- rushMetricsDF %>%
  left_join(doubleTeamDF, by = c("playerName" = "oppName"))
rushMetricsDF <- rushMetricsDF[, -c(11, 12)]
rushMetricsDF["BPR"] <- round((rushMetricsDF$blockerTot / rushMetricsDF$playTot), 4)

#Add in Combine Data to Account for Physical Metrics
fullPlayerDF <- read.csv("C:\\Users\\josep\\Dropbox\\joe\\Big Data Bowl\\FullPlayerDatabase.csv")
rushMetricsDF <- rushMetricsDF %>%
  left_join(fullPlayerDF[, c(2, 5, 6, 9:16)], by = c("playerName" = "displayName"))
rushMetricsDF <- rushMetricsDF[complete.cases(rushMetricsDF), ]

#Calculate a Players 88% of their Max Speed and Add In
maxSpeedDF <- trackDF %>%
  group_by(nflId) %>%
  summarize(maxSpeed = 2.04545* max(s, na.rm = TRUE),
            percSpeed = maxSpeed * 0.88)
rushMetricsDF <- rushMetricsDF %>%
  left_join(maxSpeedDF[, c(1, 3)], by = c("nflId" = "nflId"))

#Calculate a Player's Get Off Speed and Add In
desiredPlayersDF <- pffDF %>%
  filter(pff_role == "Pass Rush") %>%
  select(gameId, playId, nflId)
edgeTrackDF <- trackDF %>%
  mutate(time = gsub("T", " ", time)) %>%
  inner_join(desiredPlayersDF, by = c("gameId", "playId", "nflId"))  %>%
  group_by(gameId, playId, nflId) %>%
  filter(cumsum(event %in% c("ball_snap", "autoevent_ballsnap")) > 0) %>%
  filter(as.numeric(difftime(time, min(time), units = "secs")) <= 1) %>%
  ungroup() %>%
  group_by(gameId, playId, nflId) %>%
  summarise(maxSpeed = 2.04545 * max(s, na.rm = T), .groups = 'keep') %>%
  ungroup() %>%
  inner_join(playsDF, by = c("gameId", "playId")) %>%
  left_join(readrPlaysDF, by = c("gameId" = "old_game_id",
                                  "playId" = "play_id")) %>%
  filter(down != 0)
edgeTrackDF <- edgeTrackDF %>% 
  group_by(nflId) %>% 
  mutate(avgGetOffSpeed = mean(maxSpeed)) %>% ungroup()
mergeTrackDF <- edgeTrackDF %>% 
  select(nflId, avgGetOffSpeed)
rushMetricsDF <- rushMetricsDF %>%  
  left_join(mergeTrackDF, by = ("nflId")) %>% distinct()

#Get the Average Distance Between Rusher & QB From 'DF_Dist.R' File and Add In
rushMetricsDF <- rushMetricsDF %>%
  left_join(DL_distance_DF_qual[, c(1:5)], by = c("nflId" = "nflId",
                                                  "playerName" = "displayName",
                                                  "playerPos" = "officialPosition"))
colnames(rushMetricsDF)[26] <- "avgDistance"

#Make Sure All Data Points are Available for Model
rushMetricsDF <- rushMetricsDF[complete.cases(rushMetricsDF), ]

#Create a Multinomial Linear Regression to Predict 'actSuccessAvg'
succAvgLM <- lm(actSuccessAvg ~ BPR + height + weight + HandSize +
                  ArmLength + BenchPress + VertLeap + 
                  BroadJump + Shuttle + X3Cone + 
                  percSpeed + avgGetOffSpeed + avgDistance, 
                data = rushMetricsDF)
anova(succAvgLM)

#Narrow Down to Variables 95% or More Significant
succAvgLM <- lm(actSuccessAvg ~ BPR + BenchPress + 
                  VertLeap + percSpeed + avgGetOffSpeed + avgDistance, 
                data = rushMetricsDF)
anova(succAvgLM)

#Create 'predSuccessAvg' to See Expected Performance
predictDF <- predict(succAvgLM, rushMetricsDF)
rushMetricsDF["predSuccessAvg"] <- predictDF

#Calculate 'SCRT'
rushMetricsDF["SCRT"] <- rushMetricsDF$actSuccessAvg - rushMetricsDF$predSuccessAvg
