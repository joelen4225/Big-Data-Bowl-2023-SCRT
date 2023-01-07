#This file is to calculate the regression for the baseline predicted SCRT of each player
# In order to do this, we found which statistics met a 90% significance level and added to into the calculations for a players predicted SCRT

from lib2to3.pytree import Base
import pandas as pd
import statsmodels.api as sm
import numpy as np


BaselineRegression = pd.read_csv("OLineActualSCRT.csv") #OLineActualSCRT.csv has each player's actual SCRT based on first 8 weeks performance

OL_distance = pd.read_csv("OLdistance.csv")  #add all data to the FinalSCRT.csv which will have actual, predicted, and delta SCRT
OL_gos = pd.read_csv("OLGOS.csv")
OL_speed = pd.read_csv("OLspeed.csv")
OL_distance = OL_distance.rename({'nflId': 'blockPlayer'}, axis=1)
OL_gos = OL_gos.rename({'nflId': 'blockPlayer'}, axis=1)
OL_speed = OL_speed.rename({'nflId': 'blockPlayer'}, axis=1)
BaselineRegression = BaselineRegression.merge(OL_distance[['average_distance', 'blockPlayer']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
BaselineRegression = BaselineRegression.merge(OL_gos[['average_gos', 'blockPlayer']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
BaselineRegression = BaselineRegression.merge(OL_speed[['max_speed', 'max_accel', 'blockPlayer']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
BaselineRegression = BaselineRegression.merge(OL_distance[['average_distance', 'blockPlayer']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
BaselineRegression = BaselineRegression.merge(OL_distance[['average_distance', 'blockPlayer']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
BaselineRegression['RPB'] = BaselineRegression['totalRushPlayers'] / BaselineRegression['playCount']

BaselineRegression = BaselineRegression.fillna(0)
BaselineRegression.to_csv("baseline.csv", index=False)


regression_data = pd.DataFrame()
for index, row in BaselineRegression.iterrows():
    if row['3Cone'] != 0:
        regression_data = regression_data.append(row)

regression_data = regression_data[['blockPlayer', 'displayName', 'officialPosition', 'playCount', 'actualSCRT','RPB', 'height','weight', 'HandSize', 'ArmLength', '40Yard', 'BenchPress', 'VertLeap', 'BroadJump', 'Shuttle', '3Cone', 'average_distance', 'average_gos', 'max_speed', 'max_accel']]
regression_data['intercept'] = 1
y = regression_data['actualSCRT']
x = regression_data[['intercept', 'RPB', 'height','weight', 'HandSize', 'ArmLength', 'BenchPress', 'VertLeap', 'BroadJump', 'Shuttle', '3Cone', 'average_distance', 'average_gos', 'max_speed', 'max_accel']]
model = sm.OLS(y, x).fit()
scrt_delta = pd.DataFrame()
for index, row in regression_data.iterrows():
    row['predictedSCRT'] = 0.1223 + row['RPB'] * -0.0351 + row['height'] * -0.0017 + row['weight'] * 0.0001291 + row['BenchPress'] * 0.0002082 + row['3Cone'] * -0.0063 + row['average_distance'] * 0.002889
    row['deltaSCRT'] = row['actualSCRT'] - row['predictedSCRT']
    scrt_delta = scrt_delta.append(row)


BaselineRegression = BaselineRegression.merge(scrt_delta[['blockPlayer', 'deltaSCRT', 'predictedSCRT']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
BaselineRegression = BaselineRegression.merge(OL_distance[['team', 'blockPlayer']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
BaselineRegression.fillna(0)
BaselineRegression = BaselineRegression[BaselineRegression['deltaSCRT'] > 0]
BaselineRegression.to_csv("FinalSCRT.csv", index=False)
