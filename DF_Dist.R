#This R File is used to calculate average distance between pass rushers and QBs 2.3 seconds into each passing play
library(tidyverse)
library(gganimate)
library(cowplot)
library(repr)

weeks <- seq(1, 8)
trackDF <- data.frame()
for (w in weeks) {
  tempTrackDF <- read.csv(paste0("week",w, ".csv"))
  trackDF <- bind_rows(trackDF, tempTrackDF)
}

playersposDF <- playersDF %>% 
  select(nflId, officialPosition,displayName)
df_pff_merge <- pffDF %>%
  select(gameId,playId,nflId, pff_role, pff_nflIdBlockedPlayer)


trackDFdist <- trackDF
trackDFdist <- trackDFdist %>% 
  left_join(df_pff_merge, by = c("gameId","playId","nflId")) %>% 
  left_join(playersposDF, by = "nflId")

QBS <- trackDFdist %>% 
  filter(event == "qb_sack")
QBSS <- trackDFdist %>% 
  filter(event == "qb_strip_sack")
AEPI <- trackDFdist %>% 
  filter(event == "autoevent_passinterrupted")
PI <- trackDFdist %>% 
  filter(event == "pass_forward")

trackDFdist_remove <- rbind(AEPI,QBS,QBSS,PI)
trackDFdistUNQ <- trackDFdist_remove %>% filter(frameId < 29 ) %>% select(gameId,playId) %>% distinct()

sacks <- rbind(QBS,QBSS)
sacks <- sacks %>% filter(frameId < 29) %>% select(gameId,playId) %>% distinct()
speedsacks <- trackDFdist %>% 
  filter(gameId == "2021100310" & playId == "942" |
           gameId == "2021102403" & playId == "2786" |
           gameId == "2021091207" & playId == "494")
trackDFdist<-trackDFdist%>% anti_join(trackDFdistUNQ, by=c("playId", "gameId")) 

trackDFdist$event[trackDFdist$frameId == trackDFdist$frameId[trackDFdist$event == "ball_snap"] + 22] <- "desired_time"
speedsacks <- speedsacks %>% 
  filter(event == "qb_strip_sack" | event == "qb_sack")


trackDFdist <- trackDFdist %>% filter(event == "desired_time")%>% rbind(speedsacks)
tested <- trackDFdist %>% filter(event == "qb_strip_sack" | event == "qb_sack")


QB_merge <- trackDFdist %>% 
  filter(officialPosition == "QB")

QB_merge <- QB_merge %>% 
  rename('QBdisplayName' = 'displayName','QBnflId' = 'nflId','QBx' = 'x', 'QBy' = 'y', 'QBteam' = 'team', 'QBs' = 's', 'QBa' = 'a',
         'QBdir' = 'dir', 'QBdis' ='dis', 'QBo' = 'o') %>% 
  select(QBdisplayName, gameId, playId, QBnflId,QBteam,QBx, QBy)



distance_DF_DL <- trackDFdist %>% filter(pff_role == "Pass Rush") %>% 
  left_join(QB_merge, by = c("gameId","playId"), na.rm = T)


distance_DF_DL <- distance_DF_DL %>% 
  select(gameId, playId,event,nflId,displayName,officialPosition,team,x,y,QBnflId,QBdisplayName,QBteam,QBx,QBy)



distance_DF_DL <- distance_DF_DL %>% 
  group_by(gameId,playId,nflId) %>% 
  mutate("distance" = sqrt((x-QBx)^2 + (y-QBy)^2)
  ) %>% 
  ungroup()

distance_DF_DL <- distance_DF_DL %>% 
  filter(officialPosition == "DE" | officialPosition == "DT" |officialPosition == "NT"|officialPosition == "OLB" )

distance_DF_DL_Sec <- distance_DF_DL %>% 
  filter(officialPosition == "CB" | officialPosition == "S" )



distance_DF_DL <- distance_DF_DL %>% 
  filter(!is.na(distance)) %>% 
  group_by(nflId) %>% 
  mutate(average_distance = mean(distance)) %>% ungroup()

distance_DF_DL["playCounter"] <- 1
distance_DF_DL <- distance_DF_DL %>% 
  group_by(nflId) %>% 
  mutate(playtotal = sum(playCounter)) %>%ungroup()

DL_distance_DF <- distance_DF_DL %>% 
  select(nflId,displayName,officialPosition,team,average_distance,playtotal) %>% 
  distinct()

DL_distance_DF_qual <- DL_distance_DF %>% 
  filter(playtotal >= 62)
