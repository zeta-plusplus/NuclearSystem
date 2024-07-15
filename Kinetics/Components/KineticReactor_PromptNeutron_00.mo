within NuclearSystem.Kinetics.Components;

model KineticReactor_PromptNeutron_00
    /*-----------------------------------
      inheritance
      -----------------------------------*/
  extends NuclearSystem.Icons.FissionReaction;
  /*-----------------------------------
      imports
      -----------------------------------*/
  import units = Modelica.Units.SI;
  import consts = Modelica.Constants;
  import conv = NuclearSystem.Constants.UnitConversions;
  /*-----------------------------------
      parameters
      -----------------------------------*/
  
  parameter Real denNneu0_par = 1e14 "initial neutron density";
  parameter units.Volume Vol_par = 1.0;
  parameter Real kFuelDens_par = 0.001 "";
  parameter Real denNnukeFuel_par = 0.05*(19*10^6/238)*conv.factor_mole2num() "nuclear number density, [num/m3]";
  parameter units.Energy Efiss_par = 200*10^6*conv.factor_eV2J();
  parameter Real nu_par = 2.43 "average number of neutrons produced per fission";
  parameter units.Area sigmaF_par = 1.199*10^(-28) "microscopic fission cross section";
  parameter units.Velocity v_par = CmnConsts.vNeuFree_Fission_1MeV "neutron velocity";
  
  //-------------------------
  parameter Boolean use_HeatTransfer = true
  "= true to use the HeatTransfer model"
      annotation (Dialog(tab="Assumptions", group="Heat transfer"));
  parameter Boolean use_u_Vol = false
  "= true to use Vol input signal"
      annotation (Dialog(tab="General", group="Switches"));
  
  //-------------------------
  parameter NuclearSystem.Types.Switches.switch_initialization switchInitNeutron= NuclearSystem.Types.Switches.switch_initialization.FixedDerInitial annotation (Dialog(tab="Initialization", group="Switches"));
  
  parameter Real der_denNneu0_par = 0.0 if switchInitNeutron==NuclearSystem.Types.Switches.switch_initialization.FixedDerInitial "initial der(neutron density)" annotation (Dialog(tab="Initialization", group="Initial"));
  
  
  /*-----------------------------------
      internal objects
      -----------------------------------*/
  NuclearSystem.Constants.Common CmnConsts;
  Real denNnukeFuel "num density of nuclear fuel";
  Real nNukeFuel "num of nuclei";
  units.NeutronNumberDensity denNneu;
  Real nNeu "num of neutron";
  units.Time LAMBDA "neutron generation time";
  Real nu "average number of neutrons produced per fission";
  units.Area sigmaF "microscopic fission cross section";
  units.MacroscopicCrossSection SIGMAf "macroscopic fission cross section";
  units.Velocity v "neutron velocity";
  Real rho "reactivity";
  Real kEff;
  Real PHI "neutron flux, 1/(m2*s)";
  units.Volume Vol "";
  units.Power pwr "power";
  units.Energy engy "";
  Real engy_TNTeq;
  units.Time T "characteristic time(or time constant in linear system)";
  //---
  discrete units.Power pwr0 "pwr at t=0";
  discrete units.Time LAMBDA0 "neutron generation time, at time=0";
  discrete units.NeutronNumberDensity denNneu0;
  discrete Real nNeu0 "initial num of neutron";
  discrete Real rho0 "initial reactivity";
  discrete Real denNnukeFuel0 "num density of nuclear fuel";
  discrete Real nNukeFuel0 "initial num of nuclei";
  //---
  Real pwrRel0 "pwr/pwr0";
  Real denNneuRel0 "denNneu/denNneu0";
  Real derNneuqNneu "der(nNeu)/nNeu";
  //---
  /*-----------------------------------
      interfaces
  -----------------------------------*/
  Modelica.Blocks.Interfaces.RealInput u_rho "reactivity input" annotation(
    Placement(transformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {-110, 0}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Blocks.Interfaces.RealInput u_Vol if use_u_Vol "volume input" annotation(
    Placement(transformation(origin = {-110, 40}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {-110, 40}, extent = {{-10, -10}, {10, 10}})));
  //----------
  Modelica.Blocks.Interfaces.RealOutput y_pwr(unit = "W", displayUnit = "W") "" annotation(
    Placement(transformation(origin = {110, -40}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {105, -40}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Blocks.Interfaces.RealOutput y_pwrRel0 annotation(
    Placement(transformation(origin = {110, -60}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {105, -60}, extent = {{-5, -5}, {5, 5}})));
  Interface.Bus bus annotation(
    Placement(transformation(origin = {60, -100}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {-80, -100}, extent = {{-10, -10}, {10, 10}})));
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heatPort if use_HeatTransfer
    annotation (Placement(transformation(origin = {200, 0}, extent = {{-110, -10}, {-90, 10}}), iconTransformation(origin = {200, 0}, extent = {{-110, -10}, {-90, 10}})));
  Modelica.Blocks.Interfaces.RealOutput y_der_nNeu annotation(
    Placement(transformation(origin = {110, 40}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {105, 40}, extent = {{-5, -5}, {5, 5}})));
  Modelica.Blocks.Interfaces.RealOutput y_derNneuqNneu annotation(
    Placement(transformation(origin = {110, 60}, extent = {{-10, -10}, {10, 10}}), iconTransformation(origin = {105, 60}, extent = {{-5, -5}, {5, 5}})));

  //**********************************************************************
initial equation
  pwr0 = pwr;
  LAMBDA0 = LAMBDA;
  nNeu0 = denNneu0*Vol;
  nNukeFuel0= denNnukeFuel0*Vol;
//----
  denNneu0 = denNneu0_par;
  denNnukeFuel0= denNnukeFuel_par;
//----
  denNneu = denNneu0;
  
  if(switchInitNeutron==NuclearSystem.Types.Switches.switch_initialization.FixedDerInitial)then
    der(denNneu)=der_denNneu0_par;  
  end if;
  
  
//**********************************************************************
algorithm
//**********************************************************************
equation
  
  nu = nu_par;
  v = v_par;
  sigmaF= sigmaF_par;
  
  if(use_u_Vol==true)then
    Vol= u_Vol;
  else
    Vol = Vol_par;
  end if;
  
  
//----------
  when (time == 0) then
    denNneu0 = denNneu;
//-----
    pwr0 = pwr;
    LAMBDA0 = LAMBDA;
    nNeu0 = nNeu;
    rho0 = rho;
    denNnukeFuel0= denNnukeFuel;
    nNukeFuel0= nNukeFuel;
  end when;
//----------
  rho = u_rho;
  y_pwr = pwr;
  y_pwrRel0 = pwrRel0;
  y_der_nNeu= der(nNeu);
  y_derNneuqNneu= derNneuqNneu;
  
  if (use_HeatTransfer == true) then
    heatPort.Q_flow= -1.0*pwr;
  end if;
//----------
  SIGMAf = sigmaF_par*(denNnukeFuel*kFuelDens_par);
  rho = (kEff - 1)/kEff;
  LAMBDA = 1/(nu*SIGMAf*v);
//-----
  der(nNeu) = (rho /LAMBDA)*nNeu;
//-----
  nNukeFuel= nNukeFuel0;
  denNnukeFuel= nNukeFuel/Vol;
  nNeu = denNneu*Vol;
  
  PHI = denNneu*v;
  pwr = Efiss_par*SIGMAf*PHI*Vol;
  pwr = der(engy);
//-----
  engy_TNTeq = engy/(4.184*10^9);
  
  if(0.0<abs(rho))then
    T= LAMBDA/rho;
  else
    T= 0.0;
  end if;
  
//-----
  derNneuqNneu= der(nNeu)/nNeu;
  denNneuRel0 = denNneu/denNneu0;
  pwrRel0 = pwr/pwr0;
  
//----------

annotation(
    defaultComponentName = "PtRctr",
  Icon(graphics = {Rectangle(extent = {{-100, 100}, {100, -100}}), Text(origin = {0, -116}, extent = {{-100, 10}, {100, -10}}, textString = "%name")}),
  experiment(StartTime = 0, StopTime = 1, Tolerance = 1e-6, Interval = 0.002));
end KineticReactor_PromptNeutron_00;
