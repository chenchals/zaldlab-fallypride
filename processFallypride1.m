

%default parameters
default_params=@defaults_fallypride;
subjects = {
    'DND005' %not good align - set 0
    'DND007'
%     'DND014' %not good align - set 0,1,2
%     'DND016' %not good align - set 0
%     'DND018'
%     'DND022' %not good align - set 0,1,2
%     'DND023'
    };

DND005.pmodNiiFileExt = '_Sess1_all_dy.nii';  
DND005.t1Bet=[0 0.6];
DND005.petBet=[0 0.3 0.4];


processPet;