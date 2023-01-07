# Big-Data-Bowl-2023-SCRT
This is all the code our team used for our 2023 Big Data Bowl Submission. Based on the way we gave out tasks, the offense code is mainly in Python and the defense code is mainly in R. If you choose to mimic the code, you will need to update destinations of input files. Thank you and also check out our Kaggle notebook on the project.


OLine Folder (in order of development):
Scripts Folder:
    OLineAverageRushers.py: Finds the RPB (rushers per blocker) for each offensive lineman with 0.5 mean every snap the blocker played was 2 on 1 and 1 meaning every snap played was a 1 on 1. (uses helpers.py)
    OLineSumStats.py: Adds all the blocking stats (hits, hurries, sacks, wins allowed) per blocker
    ActualSCRTRegression.py: Calculates the actual SCRT performance of each offensive line player
    BaselineSCRTRegression.py: Calculates the baseline SCRT of each offensive line player

CSVs folder:
    FullPlayerDetail.csv: Combine data for each player
    OLdistance.csv: Average distance from each blocker to QB per snap 2.3 seconds into play
    OLGOS.csv: Top get off speed for each blocker in the first second of the play
    OLspeed.csv: 88% of max speed (check references for reasoning) of each blocker and max acceleration blocker reachers
    OLinePerformance.csv: Summarized stats per blocker
    OLineActualSCRT.csv: Calculated actual SCRT per blocker
    FinalSCRT.csv: The FINAL SCRT data with delta and baseline SCRT involved