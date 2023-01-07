
#EPA regression used the exisitng file of averageRushers which had a list of each player's stats
from statistics import mean
import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression
import statsmodels.api as sm
from sklearn.preprocessing import MinMaxScaler

YEAR = 2021
data_2021 = pd.read_csv('https://github.com/nflverse/nflverse-data/releases/download/pbp/' \
                   'play_by_play_' + str(YEAR) + '.csv.gz',
                   compression= 'gzip', low_memory= False)
data_2021 = data_2021.rename({'old_game_id': 'gameId', 'play_id': 'playId'}, axis=1)
passBlockDF = pd.read_csv("passBlockDF.csv")
passBlockDF = passBlockDF.merge(data_2021[['epa', 'playId' , 'gameId']], how='left', left_on=['playId', 'gameId'], right_on=['playId', 'gameId']) #get the epa per play that each blocker participated in

OLPerformance = pd.read_csv("OLinePerformance.csv") #this csv has the summarized stats for each player by adding all the plays they participated in
average_epa = pd.DataFrame()
average_epa = passBlockDF.groupby('blockPlayer', as_index=False).sum()
print(list(average_epa.columns))
print(average_epa)
OLPerformance = OLPerformance.merge(average_epa[['epa', 'blockPlayer']], how='left', left_on=['blockPlayer'], right_on=['blockPlayer'])
OLPerformance['average_epa'] = OLPerformance['epa'] / OLPerformance['playCount']

OLPerformance = OLPerformance.rename({'defWin': 'totalWinsAllowed','defHurry': 'totalHurriesAllowed', 'defSack': 'totalSacksAllowed', 'defHit': 'totalHitsAllowed' }, axis=1)
OLPerformance['totalHurriesAllowed'] *= -1
OLPerformance['totalHitsAllowed'] *= -1
OLPerformance['totalSacksAllowed'] *= -1
OLPerformance['totalWinsAllowed'] *= -1
OLPerformance['average_epa'] = OLPerformance['epa'] / OLPerformance['playCount']
regression_data = OLPerformance[['average_epa', 'totalWinsAllowed', 'totalSacksAllowed', 'totalHitsAllowed', 'totalHurriesAllowed']]
y = regression_data['average_epa']
x = regression_data[['totalWinsAllowed', 'totalSacksAllowed', 'totalHitsAllowed', 'totalHurriesAllowed']]
model = sm.OLS(y, x).fit()
print(model.summary())

OLPerformance['actualSCRT'] = (-0.305 * OLPerformance['totalWinsAllowed'] - 0.2 * OLPerformance['totalSacksAllowed'] - 0.4 * OLPerformance['totalHitsAllowed'] - 0.095 * OLPerformance['totalHurriesAllowed']) / OLPerformance['playCount']
OLPerformance.to_csv('OLineActualSCRT.csv', index=False)


