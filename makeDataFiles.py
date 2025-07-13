"""
1. Get player id's from names
2. Get a list of 50 IDs
3. Get the shot data per player
4. Save the data in a JSON file

JSON FILE FORMAT
player id
player name
shot list
"""

from nba_api.stats.endpoints import ShotChartDetail
from nba_api.stats.static import players



"""
{
    "12345": {
        "player_id": 12345,
        "player_name": "Player Name",
        "shots": [
            {
                "EVENT_TYPE": "Jump Shot",
                "SHOT_ZONE_BASIC": "Mid-Range",
                "SHOT_ZONE_AREA": "Left Side Center",
                "SHOT_ZONE_RANGE": "16-24 ft.",
                "SHOT_DISTANCE": 18.0,
                "LOC_X": -150.0,
                "LOC_Y": 200.0,
                "SHOT_MADE_FLAG": 1
            },
            {
                "EVENT_TYPE": "Layup Shot",
                "SHOT_ZONE_BASIC": "Restricted Area",
                "SHOT_ZONE_AREA": "Center",
                "SHOT_ZONE_RANGE": "Less Than 8 ft.",
                "SHOT_DISTANCE": 2.0,
                "LOC_X": 30.0,
                "LOC_Y": 10.0,
                "SHOT_MADE_FLAG": 0
            }
        ]
    }
}

"""
