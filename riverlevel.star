#River level display for Tidbyt by @savetz.bsky.social
#updated in 2024 for NOAA's newer JSON format
#Find your local gauge at https://water.noaa.gov
#FIX: Flood Stage is hardcoded because I can't figure out how to find the flood stage for any gauge

load("render.star", "render")
load("http.star", "http")
load("encoding/json.star", "json")
load("cache.star", "cache")
load("time.star", "time")

TTL = 5

def main(config):
    gauge = config.get("gauge") or 'ORCO3' #put your gauge here

    obcolor = "#4DD"
    hicolor = "#4CC"

    today = time.now()
    today = today.format("Jan _2, 2006")

    tomorrow = time.now() + time.parse_duration("24h")
    tomorrow = tomorrow.format("Jan _2, 2006")

    data = cache.get(gauge)
    if data != None:
        print("Displaying cached data for " + gauge)
    else:
        print("Fetching fresh river data for " + gauge)
        resp = http.get("https://api.water.noaa.gov/nwps/v1/gauges/" + gauge + "/stageflow")
        if resp.status_code != 200:
            fail("Request failed with status %d" % resp.status_code)

        # Parse the response as JSON if it's valid
        data = json.decode(resp.body())
        if data == None:
            fail("Failed to decode JSON response")

        cache.set(gauge, resp.body(), ttl_seconds=TTL)

    # Parse the JSON data (assuming it's successfully decoded)
    parsed_data = data

    # Extract the latest observation from observed.data
    observed_data = parsed_data["observed"]["data"]
    latest_observation = observed_data[-1]
    feet = latest_observation["primary"]
    print("We're at " + str(feet) + " feet")

    # Determine the observation category (assuming this is something you calculate based on the feet value)
    category = "Normal"
    if feet < 2.0:
        category = "Low Water"
    elif feet > 25.0:
        category = "Flood Stage"

    if category == "Normal":
        category = "                "  # Center text on display under normal conditions
    else:
        if category != "Low Water" and category != "Not defined":
            obcolor = "#C00"  # Red for any non-normal category except Low Water and Not defined

    # Find the highest projected forecast in forecast.data
    forecast_data = parsed_data["forecast"]["data"]
    highest_forecast = max(forecast_data, key=lambda x: x["primary"])
    hiproj = 'High ' + str(highest_forecast["primary"]) + " ft"
    print(hiproj)

    # Extract the time for the highest forecast
    hitime = highest_forecast["validTime"]

    # Debugging: Print to see the formats of hitime, today, and tomorrow
    #print("hitime:", hitime)
    #print("today:", today)
    #print("tomorrow:", tomorrow)

    # Convert today's and tomorrow's dates to the same format as hitime for comparison
    today_date = time.now().format("2006-01-02")  # Format today's date as YYYY-MM-DD
    tomorrow_date = (time.now() + time.parse_duration("24h")).format("2006-01-02")  #Tomorrow's date

    # Check if the high time is today or tomorrow
    if hitime[:10] == today_date:
        hitimenice = "Today " + hitime[11:16]  # If high time is today, show Today and the time
    elif hitime[:10] == tomorrow_date:
        hitimenice = "Tomorrow " + hitime[11:16]  # If high time is tomorrow, show "Tomrrw" instead of date
    else:
        # If not today or tomorrow, reformat time: replace 'T' with a space, remove ':00Z', and remove the year
        hitimenice = hitime.replace('T', ' ').replace(':00Z', '')  # Replace 'T' and remove ':00Z'
        hitimenice = hitimenice[5:]  # Remove the year and the dash (first 5 characters)

    # Print final hitimenice to see the result
    print("hitimenice:", hitimenice)


    # Assuming we calculate the high category based on the highest forecast
    hicategory = "Normal"
    if highest_forecast["primary"] > 25.0:
        hicategory = "Flood Stage"

    if hicategory != "Normal" and hicategory != "Low Water":
        hicolor = "#C00"  # Red for non-normal

    return render.Root(
        render.Column(
            expanded=True,
            main_align="center",
            cross_align="center",
            children=[
                render.Text(
                    content=str(feet) + " ft",
                    font="Dina_r400-6",
                    color=obcolor,
                ),
                render.Text(
                    content=category,
                    font="tom-thumb",
                    color=obcolor,
                ),
                render.Text(
                    content=hiproj,
                    font="tom-thumb",
                    color=hicolor,
                ),
                render.Text(
                    content=hitimenice,
                    font="tom-thumb",
                    color=hicolor,
                ),
            ],
        )
    )

