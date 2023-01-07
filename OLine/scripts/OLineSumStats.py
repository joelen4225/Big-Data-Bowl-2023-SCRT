#This file sums up the total stats for the blockers for each play they participated in (wins, hits, hurries, sacks are counted)
import pandas as pd

passBlockDF = pd.read_csv('passBlockDF.csv')
passBlockDF['playCount'] = 1
summary = passBlockDF.groupby('blockPlayer', as_index=False).sum()
OLPerformance = pd.read_csv("OLinePerformance.csv")
OLPerformance = OLPerformance.merge(summary[['defWin', 'defHit', 'defHurry', 'defSack', 'playCount', 'blockPlayer']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
playerDetail = pd.read_csv("FullPlayerDetail.csv")
playerDetail = playerDetail.rename({'nflId': 'blockPlayer'}, axis=1)
OLPerformance = OLPerformance.merge(playerDetail[['displayName', 'officialPosition', 'HandSize', 'ArmLength', '40Yard', 'BenchPress', 'VertLeap', 'BroadJump', 'Shuttle', '3Cone', 'height', 'weight', 'blockPlayer']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
OLPerformance.drop(OLPerformance.index[(OLPerformance["officialPosition"] == "RB")],axis=0,inplace=True)
OLPerformance.drop(OLPerformance.index[(OLPerformance["officialPosition"] == "TE")],axis=0,inplace=True)
OLPerformance.drop(OLPerformance.index[(OLPerformance["officialPosition"] == "FB")],axis=0,inplace=True)
OLPerformance.drop(OLPerformance.index[(OLPerformance["officialPosition"] == "WR")],axis=0,inplace=True)
OLPerformance = OLPerformance[OLPerformance['playCount'] >= 75]
OLPerformance = OLPerformance.fillna(0)
OLPerformance.to_csv("OLinePerformance.csv", index=False)
