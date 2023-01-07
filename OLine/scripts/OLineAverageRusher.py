#This file sums up the total number of rushers that each blocker faced over the first 8 weeks of the season
import pandas as pd
from helpers import sumRushers

playsDF = pd.read_csv("input/plays.csv")
playersDF = pd.read_csv("input/players.csv")
pffDF = pd.read_csv("input/pffScoutingData.csv")
passBlockDF = pd.read_csv("passBlockDF.csv") #all plays from the PFF Scouting Data from the first 8 weeks of the season

averageRushers = pd.DataFrame()
averageRushers = averageRushers.reindex(columns = averageRushers.columns.tolist() + ["blockPlayer", "totalRushPlayers"])

playIndex = 0.0
currentPlays = pd.DataFrame()
for index, row in passBlockDF.iterrows():
    if playIndex != row['playId']:
        if playIndex != 0.0:
            averageRushers = sumRushers(currentPlays, averageRushers)
        currentPlays = currentPlays.iloc[0:0]   
        playIndex = row['playId']
        currentPlays = currentPlays.append([row])
    else:
        currentPlays = currentPlays.append([row])

averageRushers.to_csv('OLPerformance.csv') 