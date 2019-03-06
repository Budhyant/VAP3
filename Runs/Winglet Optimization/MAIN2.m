clc
clear

clc
clear

% cores = 32;
% parpool(cores,'IdleTimeout',800)
home_dir = pwd;

delete opthistory.txt
delete dvhistory.txt

lb = [...
    0.01 0.1 0 0.04 0 ... % Lop location, f trans chord, f trans twist, rear trans chord, rear trans twist
      0.30 6.8 0.38 0.04 -3 ... % 
      0.30 6.8 0.38 0.04 -5 ...
      0.30 6.8 0.3 0.04 -3 ...
      0.30 6.8 0.3 0.04 -5 ...
    ];

ub = [ ...
    0.7 0.15 5 0.15 5 ... 
      0.60 7.49 0.9 0.3 5 ...
      0.60 7.50 0.9 0.3 5 ...
      0.60 7.49 0.9 0.3 5 ...
      0.60 7.50 0.9 0.3 5 ...
    ];


A = [... 
    -1 0 0 0 0 ... % Front tip going outward (inboard)
        0 -1 0 0 0 ...
        0 0 0 0 0 ...
        0 0 0 0 0 ...
        0 0 0 0 0; ...
        
    0 0 0 0 0 ... % Front tip going outward (outboard)
        0 1 0 0 0 ...
        0 -1 0 0 0 ...
        0 0 0 0 0 ...
        0 0 0 0 0; ...        
        
    -1 0 0 0 0 ... % rear tip going outward (inboard)
        0 0 0 0 0 ...
        0 0 0 0 0 ...
        0 -1 0 0 0 ...
        0 0 0 0 0; ...
        
    0 0 0 0 0 ... % rear tip going outward (outboard)
        0 0 0 0 0 ...
        0 0 0 0 0 ...
        0 1 0 0 0 ...
        0 -1 0 0 0; ... 
        
    0 1 0 0 0 ... % rear behind front (inboard)
        1 0 0 0 0 ...
        0 0 0 0 0 ...
        -1 0 0 0 0 ...
        0 0 0 0 0; ...        
  
    0 0 0 0 0 ... % rear behind front (outboard)
        0 0 0 0 0 ...
        1 0 0 1 0 ...
        0 0 0 0 0 ...
        -1 0 0 0 0; ...  
 
    0 0 0 0 0 ... % rear under front (inboard)
        0 0 -1 0 0 ...
        0 0 0 0 0 ...
        0 0 1 0 0 ...
        0 0 0 0 0; ...        
  
    0 0 0 0 0 ... % rear under front (outboard)
        0 0 0 0 0 ...
        0 0 -1 0 0 ...
        0 0 0 0 0 ...
        0 0 1 0 0; ...  
        
    0 1 0 0 0 ... % outboard rear behind inboard front
        1 0 0 0 0 ...
        0 0 0 0 0 ...
        0 0 0 0 0 ...
        -1 0 0 0 0; ...       
 
    0 0 0 0 0 ... % outboard rear under inboard front
        0 0 -1 0 0 ...
        0 0 0 0 0 ...
        0 0 0 0 0 ...
        0 0 1 0 0; ...      
        
    0 -1 0 0 0 ... % Taper front inner
        0 0 0 1 0 ...
        0 0 0 0 0 ...
        0 0 0 0 0 ...
        0 0 0 0 0; ...  
        
    0 0 0 0 0 ... % Taper front outer
        0 0 0 -1 0 ...
        0 0 0 1 0 ...
        0 0 0 0 0 ...
        0 0 0 0 0; ...  
        
    0 0 0 -1 0 ... % Taper rear inner
        0 0 0 0 0 ...
        0 0 0 0 0 ...
        0 0 0 1 0 ...
        0 0 0 0 0; ...  
        
    0 0 0 0 0 ... % Taper rear outer
        0 0 0 0 0 ...
        0 0 0 0 0 ...
        0 0 0 -1 0 ...
        0 0 0 1 0; ...  
       
      ];

b = [...
    -7.65; % front tip going outward (inboard)
    -0.03; % front tip going outward (outboard)
    -7.65; % rear tip going outward (inboard)
    -0.03; % rear tip going outward (outboard)
    -0.05; % rear behind front (inboard)
    -0.05; % rear behind front (outboard)
    -0.01; % rear under front (inboard)
    -0.01; % rear under front (outboard)
    -0.05; % outboard rear behind inboard front
    -0.05; % outboard rear under inboard front
    0;
    0;
    0;
    0;
    ];

Aeq = [];
beq = [];

nvars = 25;
TolCon_Data = 1e-6; 
TolFun_Data = 1e-08;

Seed = [];

options = gaoptimset;
options = gaoptimset(options,'TolFun', TolFun_Data);
options = gaoptimset(options,'Display', 'iter');
options = gaoptimset(options,'InitialPopulation', Seed);
options = gaoptimset(options,'PlotFcns', {  @gaplotbestf @gaplotbestindiv @gaplotexpectation @gaplotscorediversity @gaplotstopping });
options = gaoptimset(options,'Vectorized', 'off');
options = gaoptimset(options,'UseParallel', 1 );
options = gaoptimset(options,'Generations',1000,'StallGenLimit', 50);
[x,fval,exitflag,output,population,score] = gamultiobj({@fcnOBJECTIVE2, home_dir},nvars,A,b,Aeq,beq,lb,ub,[],options);
