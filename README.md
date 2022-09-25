# Airthings plotter

A Matlab/Octave script that plots raw data provided by Airthings Wave air quality monitor.

The script also *undo* the 24h average of the Radon data. "Instant" 1h data and corresponding 6h averages are also plotted.

Ángel Rodés, 2022 \
[www.angelrodes.com](https://www.angelrodes.com/)

## How to use

1. Follow the instructions from your Airthings Wave Plus monitor to setup the app in your phone. Create a new account if you don't have one.
2. After a few hours, you can log in and see your data online at [dashboard.airthings.com](https://dashboard.airthings.com/)
3. Download your by clicking "Export to CSV":
![image](https://user-images.githubusercontent.com/53089531/191995763-0887d323-0b59-41bb-aa67-84ccd3095d4e.png)
4. Run the script ```Plot_airthings_v1.m``` in MATLAB or Octave to get your raw data plotted.

## Output

The script will ask for the CSV file:

![image](https://user-images.githubusercontent.com/53089531/191996233-8f77abce-fcce-444a-b8ef-7f97279a4713.png)

It also lets you choose how many days to plot:

![image](https://user-images.githubusercontent.com/53089531/191992157-b0210de1-4d3d-471a-814c-ede03e683d81.png)

The first figure looks like this:

![image](https://user-images.githubusercontent.com/53089531/191994587-eac1e5b2-b108-4b6a-88e7-ed3a6049b0fd.png)

A second figure with the Radon data and calculated values is also produced:

![imagen](https://user-images.githubusercontent.com/53089531/192147052-afa10d96-bd8a-4f7c-b348-3180d7a2236f.png)

See below for an explanation of the short term data.

## Potential issues

Your csv should look like this:

![image](https://user-images.githubusercontent.com/53089531/191991075-5900ab53-ddfc-4321-a3cf-71188a065a8a.png)

If you have a different model you might get other data, or data separated by comma (,) instead of semicolon (;). If that is the case, you can change the first lines of the "load data" and "plot sttuff" sections in the script to make it work with you monitor.

## Calculated short-term Radon data

Airthings detector are [designed, made and sold to collect long term averages](https://help.airthings.com/en/articles/3119759-radon-how-is-radon-measured-how-does-an-airthings-device-measure-radon). That is why the detector reports 24h averages. Actually, [Airthings](https://www.airthings.com/) recommends to use their productos for a month to get accurate measurements.

However, some of us are very impatient and want to use their porduts to test the mitigation actions we take in our houses and offices (e.g. opening windows) in a much shorter term. Of course, this means that **we should forget about accuracy here!**

As these detectors calculate the Radon concentrations based on alpha particle counting, the **precission** of the measurments will be affected by counting statistics. Therefore, to estimate the uncertainty of the short term measurements, I will assume that the uncertainty will be reresented by the formula ```100/N^0.5```, where ```N``` is the number of events (alpha decays) counted by the detector.

If we assume a conserviative precision of 10% on the reported 24h measurements, "instant" 1h average in the Radon should yield about 50% uncertainties. Obviusly, this uncertainty shuld decrease with higher Radon concentrations. In our tests, the scatter of the generated 1h values seem to rougly reflect these 50% uncertainties for values around 500 Bq/m3 (see last plot above). This implies, *very rougly*, 1 event detected per hour for each 100 Bq/m3 concentration.

Following the same principle, 6h averages (solid green line) should have around 20% uncertainties (dashed green line).
