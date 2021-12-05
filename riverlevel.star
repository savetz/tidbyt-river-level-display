#River level display for Tidbyt by @KaySavetz
#Find your local gauge at https://water.weather.gov/ahps/

load("render.star", "render")
load("re.star", "re")
load("http.star", "http")
load("cache.star", "cache")
load("time.star", "time")

TTL = 600

def main(config):
    gauge = config.get("gauge") or 'prto3' #replace prto3 with your chosen gauge

    obcolor = "#4DD" 
    hicolor = "#4CC" 

    today = time.now()
    today = today.format("Jan _2, 2006")
    print(today)

    tomorrow = time.now() + time.parse_duration("24h")
    tomorrow = tomorrow.format("Jan _2, 2006")

    data = cache.get(gauge)
    if data != None:
      print("Displaying cached data for " + gauge)
    else:
      print("Fetching fresh river data for " + gauge)
      resp = http.get("https://water.weather.gov/ahps2/rss/alert/" + gauge + ".rss")
      if resp.status_code != 200:
        fail("Request failed with status %d", resp.status_code)

      data = resp.body()
      cache.set(gauge, data, ttl_seconds=TTL)

    element = re.match('Latest Observation: ([0-9]*.?[0-9]*) ft', data)
    if element:
        feet = element[0][1]
        print("We're at " + str(feet) + " feet")
    else:
        print("No latest observation")
        feet = "???"

    element = re.match('Latest Observation Category: (.*?)&', data)
    if element:
        category = element[0][1]
        print("Category is " + category)
        if category == "Normal":   #only show category if at alert level
            category = "                "  #hack to center text on display under normal conditions
        else:
            if category != "Low Water" and category != "Not defined":
                obcolor = "#C00"  #red for any non-normal category except Low Water and Not defined
    else:
        print("No category")
        category = "                "

#This is here if you need it, but I didn't end up using it
#    element = re.match('Observation Time: (.*?) -', data)
#    if element:
#        obtime = element[0][1]
#        print("Observation time is " + obtime)
#    else:
#        print ("No observation time")
#        obtime = "unknown"

    element = re.match('Highest Projected Forecast Available: ([0-9]*.?[0-9]*) ft', data)
    if element:
        hiproj = 'High ' + element[0][1] + " ft"
        print(hiproj)
    else:
        print ("No projected high")
        hiproj = ""

    element = re.match('Highest Projected Forecast Time: (.*?) -', data)
    if element:
        hitime = element[0][1]
        print("High time " + hitime)
    else:
        print ("No projected high time")
        hitime = ""

    if not hiproj:
        hitime = ""  #don't show projected hi time if there's no high projection

    if hitime[0:6] == today[0:6]:
        hitime = hitime[6:99] #if high time is today, don't show the date, just the time
    if hitime[0:6] == tomorrow[0:6]:
        hitime = "Tomrrw " + hitime[6:99] #if high time is tomorrow, show "Tomrrw" instead of date
    hitimenice = re.sub(', 20[1-9][0-9]','',hitime) #don't display the year
    hitimenice = re.sub('  ',' ',hitimenice) #squish two spaces to one
    hitimenice = re.sub(' 0',' ',hitimenice) #remove 0 before hour

    element = re.match('Highest Category: (.*?)&', data)
    if element:
        hicategory = element[0][1]
        print("High Category is " + hicategory)
        if hicategory != "Normal" and hicategory != "Low Water":
            hicolor = "#C00"  #red for non-normal
    else:
        print ("No projected high category")
        hicategory = ""

    return render.Root(
        render.Column(
            expanded=True,
            main_align="center",
            cross_align="center",
            children=[
                render.Text(
                    content = (str(feet) + " ft"),
                    font = "Dina_r400-6",
                    color = obcolor,
                ),
                render.Text(
                    content = (category),
                    font = "tom-thumb",
                    color = obcolor,
                ),
                render.Text(
                    content = (hiproj),
                    font = "tom-thumb",
                    color = hicolor,
                ),
                render.Text(
                    content = (hitimenice),
                    font = "tom-thumb",
                    color = hicolor,
                ),
             ],
        )
    )
