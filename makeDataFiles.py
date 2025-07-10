"""
1. Get player id's from names
2. Get a list of 50 ID's
3. Get the shot data per player
4. Save the data in a JSON file

JSON FILE FORMAT
player id
player name
shot list
"""

from nba_api.stats.endpoints import ShotChartDetail
from nba_api.stats.static import players

def getPlayerNamesFromFile(file_path: str) -> list[str]:
    """
    Read player names from a file and return them as a list.

    Args:
        file_path (str): The path to the file containing player names.

    Returns:
        list[str]: A list of player names.

    """

    with open(file_path, 'r') as file:
        player_names = [line.strip() for line in file if line.strip()]
    return player_names

def getPlayerID(name: str) -> int or None:
    """
    Get the player ID for a given player name.

    Args:
        name (str): The name of the player.

    Returns:
        int: The player ID.
    """
    matches = players.find_players_by_full_name(name)
    if matches:
        return matches[0]['id']
    return None

def getSeasonShots(player_id: int, season: str = '2024-25') -> list[dict]:
    """
    Gets the shot data for a specific player in a given season.

    Args:
        player_id (int): The ID of the player.
        season (str): The season for which to retrieve shot data (default is '2024-25').

    Returns:
        list[dict]: A list of dictionaries containing shot data for the player.
    """
    shotlog = ShotChartDetail(
        team_id = 0,  # 0 = all teams
        player_id = player_id,
        season_nullable = '2024-25',
        season_type_all_star = 'Regular Season',
        context_measure_simple = 'FGA'  # crucial to include missed shots
    )

    return shotlog.get_data_frames()[0]

if __name__ == "__main__":
    for name in getPlayerNamesFromFile('players.txt'):
        player_id = getPlayerID(name)
        if player_id:
            shots = getSeasonShots(player_id, '2024-25') # Add this list to the file

"""
{
    player_id: ####,
    player_name: "Player Name",
    shots: [
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
        ...
    ]
}
"""
