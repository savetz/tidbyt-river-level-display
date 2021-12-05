# Tidbyt River Level Display
Show the observed water level at your chosen U.S. river gauge and the forecast high water level on a [Tidbyt](https://tidbyt.com/) display, using data from the National Weather Service.
 
If the observed level or forecast high level is above normal (e.g. near flood stage or flooding) the information is shown in red.

## Quick start
1. Install [`pixlet`](https://github.com/tidbyt/pixlet)
2. Run `pixlet serve riverlevel.star`
3. Go to [http://localhost:8080](http://localhost:8080)
    1. `?gauge=ltln6` can be passed to display a different gauge than the default.
4. Find your local gauge at https://water.weather.gov/ahps/
5. You may want to change your default gauge on line 13

![Preview](screenshot1.png)
![Preview](screenshot2.png)
![Preview](screenshot3.png)
