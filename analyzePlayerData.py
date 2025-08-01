"""
Right now, we have a video analysis of a submitted video which really doesn't do anything.
For Accuracy tests, we want to set up a JSON file just like the one we have for the player data.

This is an example "7-31-25.json"

{
    shots: [
        {
            -- "EVENT_TYPE": "Jump Shot",
            -- "SHOT_ZONE_BASIC": "Mid-Range",
            -- "SHOT_ZONE_AREA": "Left Side Center",
            -- "SHOT_ZONE_RANGE": "16-24 ft.",
            -- "SHOT_DISTANCE": 18.0,
            "LOC_X": -150.0,
            "LOC_Y": 200.0,
            "SHOT_MADE_FLAG": 1
        },
        ...
    ]
}
"""