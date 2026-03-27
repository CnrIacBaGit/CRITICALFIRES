# CRITICALFIRES
CRITICALFIRES is a software demonstrator developed within the RETURN project, Spoke 4–VS4. It is an integrated model for Critical Zone–Carbon–Wildfire interaction, designed to assess how Mediterranean soil–vegetation systems respond to wildfires, drought, and management strategies under environmental change.

CRITICALFIRES is a MATLAB implementation of an integrated Vegetation–Fire–Soil model designed to simulate the coupled dynamics of vegetation succession, wildfire ignition/propagation, and soil organic carbon using a RothC-style framework. The model is spatially explicit on a regular grid and uses a monthly time step. 

## Project context

CRITICALFIRES was conceived to assess how Mediterranean soil–vegetation systems, viewed as a key component of the terrestrial Critical Zone, respond to wildfires, drought, and management strategies under environmental change. It is a simplified model for evaluating ecosystem response in Mediterranean environments, with particular attention to carbon storage capacity and to the influence of soil and vegetation characteristics on wildfire risk, including the possible effects of management actions. 

The tool is intended for both researchers, who may use it to simulate the long-term dynamics of the soil–vegetation–fire system under climate and management change, and land managers, who may use it to explore the possible effectiveness of alternative management strategies on ecosystem dynamics and health. The project documentation also states an important limitation: the model is simplified and is meant to provide scenario-based indications on ecosystem and soil dynamics, not event-specific fire forecasts.

## What the model does

The model couples three interacting components: a vegetation succession module, a soil carbon dynamics module based on RothC, and a wildfire ignition and propagation module. According to the project sheet, the integrated framework explicitly represents reciprocal interactions between vegetation and soil, while including wildfire ignition, spread, and effects on both subsystems. The intended spatial scale is typically between 20 and 100 m, with monthly temporal resolution, while fires occur on faster time scales within the reference month. 

In the formulation documented in Deliverable D3, vegetation is represented through fractional covers of bare soil (`B`), grass (`G`), shrubs (`S`), seeders / woody pioneers (`P`), and resprouters / mature woody vegetation (`H`). Soil carbon is represented through RothC-style pools: DPM, RPM, BIO, HUM, plus the inert pool IOM. Fire affects vegetation by removing biomass according to class-dependent severity parameters and affects the soil by removing part of the active organic carbon pools. 

## Repository structure

The main MATLAB files are:

- `main_soilVegFire.m` – main execution script
- `default_params.m` – model parameters
- `make_climate.m` – monthly climate forcing generator
- `init_state.m` – initialization of vegetation fractions and soil carbon pools
- `simulate_model.m` – main monthly simulation loop
- `fire_probability.m` – monthly fire probability calculation
- `propagate_fire_simple.m` – optional fire spread across neighboring cells
- `update_model_one_month.m` – coupled monthly update of vegetation, fire, and soil
- `compute_betas.m` – vegetation transition rates
- `vegetation_carbon_input.m` – vegetation-to-soil carbon inputs
- `rothc_rho.m` – environmental multiplier for RothC decomposition
- `rothc_temp_factor_centered.m` – temperature modifier centered on a reference mean annual temperature


## Model overview

The model runs on a regular grid of size `Ny x Nx` with monthly time step
h = 1/12 [year].

At each month, the workflow is:

1. compute fire probability for each grid cell;
2. draw stochastic ignition cell by cell;
3. optionally propagate fire to neighboring cells;
4. update vegetation cover fractions;
5. update soil carbon pools;
6. store time series and optional map snapshots.



## Vegetation module

Vegetation is described by fractional covers:

- `B` = bare soil
- `G` = grass
- `S` = shrubs
- `P` = seeders / intermediate woody vegetation
- `H` = resprouters / mature woody vegetation

The vegetation module simulates succession among these classes through transition rates such as bare-soil-to-grass, grass-to-shrub, shrub-to-woody classes, and seeders-to-resprouters. In the formulation the long-term undisturbed tendency is toward a closed vegetation state dominated by resprouters. In the no-fire equilibrium simulation for Spotorno, the model converges toward `(B, G, S, P, H) = (0, 0, 0, 0, 1)`, i.e. a closed successional state dominated by resprouters. 

In this codebase, vegetation transition rates are modulated by a soil-carbon feedback and can also be optionally modulated by soil moisture. After each monthly update, vegetation fractions are constrained to remain non-negative and renormalized to sum to one.

## Fire module

The fire module includes:

- monthly fire probability per cell,
- stochastic ignition,
- optional deterministic local spread to neighboring cells.

The monthly fire probability is described as depending on a baseline annual fire parameter, vegetation-dependent flammability, seasonality, and soil-moisture limitation. Fire spread is implemented as threshold-based propagation to neighboring cells, iterated up to a prescribed maximum number of steps; in the simulations an 8-neighbor propagation rule is used with a maximum of 10 iterations. 

The project sheet also states that CRITICALFIRES can incorporate either a simplified propagation routine or a more refined propagation model such as Propagator. 

## Soil carbon module

The soil component follows a RothC-style structure with the pools:

- `DPM` – Decomposable Plant Material
- `RPM` – Resistant Plant Material
- `BIO` – Microbial Biomass
- `HUM` – Humified Organic Matter
- `IOM` – Inert Organic Matter

Active soil organic carbon is typically tracked as

\[
SOC = DPM + RPM + BIO + HUM
\]

while `IOM`  is computed from total organic carbon using the standard Falloon-type relationship and then kept constant during the simulations. 

Decomposition is modulated by environmental conditions through temperature, soil moisture, and vegetation cover. Vegetation supplies carbon inputs to the soil, and fire can both remove active SOC and redistribute part of burned biomass toward soil pools, depending on the selected parameterization. The project sheet explicitly identifies carbon exchange between vegetation and soil as one of the essential coupled processes represented by the model. 

## Climate forcing

Climate forcing is generated monthly and replicated across the grid. The main forcing variables are:

- air temperature,
- rainfall,
- evaporation,
- cumulative soil moisture deficit,
- RothC soil-moisture factor.

Application uses a repeated monthly climatology of air temperature, rainfall, and evaporation, together with a soil moisture deficit calculation consistent with the RothC scheme. The nominal active soil depth is set to 23 cm, clay content to 30%, and the corresponding absolute maximum soil moisture deficit is approximately 50 mm. 

## How to run

Run the model in MATLAB from:

```matlab
main_soilVegFire
