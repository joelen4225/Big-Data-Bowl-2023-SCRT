from cmath import nan
import pandas as pd
import numpy as np
import csv

#This function sums the total number of rushers that each blocker faced with a 1 on 1 counting as 1 rusher and a 2 on 1 counting as 0.5 rusher
def sumRushers(currentPlays, OLinePerformance):
    currentPlays = currentPlays.fillna(0)
    counts = currentPlays['rushPlayer'].value_counts()
    counts = dict(counts)
    for index, row in currentPlays.iterrows():
        if row['rushPlayer'] == 0:
            continue
        if counts[row['rushPlayer']] == 1:
            if row['blockPlayer'] not in OLinePerformance['blockPlayer'].values:
                print("SINGLE TEAM")
                added_row = {'blockPlayer': row['blockPlayer'], 'totalRushPlayers': 1, 'totalPlays': 1, 'totalWinsAllowed': row['defWin'], 'totalHitsAllowed': row['defHit'], 'totalHurriesAllowed': row['defHurry'], 'totalSacksAllowed': row['defSack']}
                OLinePerformance = OLinePerformance.append(added_row, ignore_index=True)
            else:
                print("SINGLE TEAM INSIDE")
                index = OLinePerformance.index[OLinePerformance['blockPlayer']==row['blockPlayer']]
                OLinePerformance.loc[index[0], 'totalRushPlayers'] += 1
        elif counts[row['rushPlayer']] == 2:
            if int(row['blockPlayer']) not in OLinePerformance['blockPlayer'].values:
                print("DOUBLE TEAM")
                added_row = {'blockPlayer': row['blockPlayer'], 'totalRushPlayers': 0.5, 'totalPlays': 1, 'totalWinsAllowed': row['defWin'], 'totalHitsAllowed': row['defHit'], 'totalHurriesAllowed': row['defHurry'], 'totalSacksAllowed': row['defSack']}
                OLinePerformance = OLinePerformance.append(added_row, ignore_index=True)
            else:
                print("DOUBLE TEAM INSIDE")
                index = OLinePerformance.index[OLinePerformance['blockPlayer']==row['blockPlayer']]
                OLinePerformance.loc[index[0], 'totalRushPlayers'] += 0.5
        else:
            print("triple team") 
    return OLinePerformance

