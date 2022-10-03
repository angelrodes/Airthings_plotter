# Airthings plotter

A Matlab/Octave script that plots raw data provided by Airthings Wave air quality monitor.

Version 2 of the script also *undo* the 24h average of the Radon data. "Instant" 1h data and corresponding 6h averages are also plotted.

Ángel Rodés, 2022 \
[www.angelrodes.com](https://www.angelrodes.com/)

## How to use

1. Follow the instructions from your Airthings Wave Plus monitor to setup the app in your phone. Create a new account if you don't have one.
2. After a few hours, you can log in and see your data online at [dashboard.airthings.com](https://dashboard.airthings.com/)
3. Download your by clicking "Export to CSV":
![image](https://user-images.githubusercontent.com/53089531/191995763-0887d323-0b59-41bb-aa67-84ccd3095d4e.png)
4. Run the script ```Plot_airthings_v2.m``` in MATLAB or Octave to get your raw data plotted.

If you are using Linux and you have Octave installed, you can just run this in your terminal:

```bash
wget -O - https://raw.githubusercontent.com/angelrodes/Airthings_plotter/main/Plot_airthings_v5.m | octave
```

## Output

The script will ask for the CSV file:

![image](https://user-images.githubusercontent.com/53089531/191996233-8f77abce-fcce-444a-b8ef-7f97279a4713.png)

It also lets you choose how many days to plot:

![image](https://user-images.githubusercontent.com/53089531/191992157-b0210de1-4d3d-471a-814c-ede03e683d81.png)

The first figure looks like this:

![image](https://user-images.githubusercontent.com/53089531/191994587-eac1e5b2-b108-4b6a-88e7-ed3a6049b0fd.png)

A second figure with the Radon data and calculated values is also produced (from v2):

![imagen](https://user-images.githubusercontent.com/53089531/192149940-fcef0aec-8511-4294-acb7-5dbad4b8a7e2.png)

See below for an explanation of the short term data.

## Potential issues

Your csv should look like this:

![image](https://user-images.githubusercontent.com/53089531/191991075-5900ab53-ddfc-4321-a3cf-71188a065a8a.png)

If you have a different model you might get other data, or data separated by comma (,) instead of semicolon (;). If that is the case, you can change the first lines of the "load data" and "plot sttuff" sections in the script to make it work with you monitor.

## Calculated short-term Radon data in version 2+

Airthings detector are [designed, made and sold to collect long term averages](https://help.airthings.com/en/articles/3119759-radon-how-is-radon-measured-how-does-an-airthings-device-measure-radon). That is why the detector reports 24h averages. Actually, [Airthings](https://www.airthings.com/) recommends to use their productos for a month to get accurate measurements.

However, some of us are very impatient and want to use their porduts to test the mitigation actions we take in our houses and offices (e.g. opening windows) in a much shorter term. Of course, this means that **we should forget about accuracy here!**

As these detectors calculate the Radon concentrations based on alpha particle counting, the **precission** of the measurments will be affected by counting statistics. Therefore, to estimate the uncertainty of the short term measurements, I will assume that the uncertainty will be reresented by the formula ```100/N^0.5```, where ```N``` is the number of events (alpha decays) counted by the detector.

If we assume a conserviative precision of 10% on the reported 24h measurements, "instant" 1h-data should yield about 50% uncertainties. Obviusly, this uncertainty shuld decrease with higher Radon concentrations. In our initial tests, the scatter of the generated 1h-data seem to rougly reflect these 50% uncertainties for values around 500 Bq/m3 (see last plot above). This implies that, *very rougly*, 1 event is detected per hour for each 100 Bq/m3 concentration.

Scatter of teh "1h data" in our initial tests and assumed uncertainty based on 1 count per 100 Bq/m3:

![image](https://user-images.githubusercontent.com/53089531/192155481-4bb32e3d-6e3a-43b5-9bd9-f633d1359bd3.png)

Following the same principle, 6h moving averages (solid green line in the plot below) should have around 20% uncertainties (dashed green lines). Uncertainties are calculated assuming  ``` N = [Rn]/100 * Δt```, being ```[Rn]``` the concentration in Bq/m3 and ```Δt``` the number of 1h data points considered.

![image](https://user-images.githubusercontent.com/53089531/192155570-eee26339-dc1d-4f6a-90d3-a38e16f0e873.png)

**6h moving average is plotted to test short-term "experiments".** This value is calculated as an average of 7 1h-data-points: from 3 hours before to 3 hours after. Therefore, **this is a moving average, not the average of the previous 6 hours.** Consequently, first and last 6h averages are the average of the first and last 4 data points respectively.

## changelog

Version 2: 

- Includes the calculation of 1h data
- Include a second plot with Radon data only.
- Plots the 6h moving average.

Version 3: 

- 6h moving average replaced by smoothed 12h average.
- Added day of week to Radon plots.

Version 4:

- Improved the inverse method to *guess* the "instant 1h data". No need for later correction of negative data.
- Back to 6h moving average.
- Colours changed.

Version 5:

- Improved the inverse method to *guess* the "instant 1h data": now this is calculated for each 5 minutes (300 seconds), even if we have gaps in the data reported.
- Added a Black & Wite version of the Radon plot if mylaptop>0.
