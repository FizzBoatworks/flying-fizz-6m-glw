//Fizz 6m Engine Script Giulia Farnese
//This script is based on the "Elementary Sail Boat Script" by Dora Gustafson 2017
//Modified by LaliaCasau 2022..
//Modified by Giulia Farnese 2023..
//
//VARIABLE NAMING
//I am using the Azn Min (itoibo) system with some variation, which uses two letters to describe the scope and data type of each variable.
//The first letter is the scope: g-global l-local c-constant p-parameter
//The second letter is the data type: i-integer f-float s-string k-key v-vector r-rotation a-array(list)   
//

//CONSTANTS
integer MSGTYPE_GLWPARAMS=70001;  //receive glw params
integer MSGTYPE_RESET=70003;
integer MSGTYPE_SAILING=70004;
integer MSGTYPE_MOORED=70005;
integer MSGTYPE_BOATPARAMS=70006;  //Boat params for shadow wind
integer MSGTYPE_GLWINITIALIZE=70007;
integer MSGTYPE_WINDINFO=70008;
integer MSGTYPE_RECOVERY=70009;
integer MSGTYPE_MYWIND=70010;  //mywind/cruising mode, personal wind
integer MSGTYPE_GLWIND=70011;  //glwind mode, for cruises
integer MSGTYPE_RACING=70012;  //racing mode, for races
integer MSGTYPE_WORLDWIND=70013;  //world wind mode, to sailing

//SOUNDS
string gsSoundSailSlow="slow";
string gsSoundSailFast="sailing";
string gsSoundSailPlane="planing";
string gsSoundRaise="glw_dboat_raise";
string gsSoundLower="glw_dboat_lower";

//HUD COLORS
vector cvBlue = <0.0, 0.455, 0.851>; //hud color
vector cvGreen = <0.18, 0.8, 0.251>; //hud color
vector cvYellow = <1.0, 0.863, 0.0>; //hud color
vector cvRed = <1.0, 0.255, 0.212>; //hud color

//STEERING CONSTANTS
float  cfThreeDEG = 3;         //degrees that the sail moves when pressing the arrows.  Then convert to radians
float  cfOneDEG = 1;           //degrees that the sail moves when pressing the PgUp pgDown.  Then convert to radians  

//BOAT SHADOW CONSTANTS
integer sailArea=25;  //for shadow wind may not be zero;
string  boatLength2Bow="1.5"; //for shadow wind
string  boatLength2Stern="2.1"; //for shadow wind

//BOAT CONSTANTS
float  cfHeelFactor = .1;

//GENERAL CONSTANTS
float  cfTime = 4.0;           //default settimerevent
float  cfFloatLevel=-0.75;   //0.0 offset of the boats hover height;
integer ciPeriod=120;
float  cfPosZ=19.470;
float  cfKt2Ms=0.514444;
string csMsgChangeWind="To take the GLW wind you have to be in personal wind mode, type 'mywind' or 'cruising'";

//SAIL CONSTANTS
float  cfSailFactor = 1.00;   
float  cfMaxSail = 59;         
float  cfMinSail = 10;

//SAIL, RUDDER, & WAKE CONFIG CONSTANTS         
vector cvMainPosOpen=<0.42820, 0.00000, 5.54930>;       
vector cvMainPosClose=<0.42820, 0.00000, 1.48720>;         
vector cvMainSizeOpen=<6.28077, 0.62823, 8.03341>;   
vector cvMainSizeClose=<6.28077, 0.01000, 0.01000>;  
vector cvMainRotOpen=<0.00000, -4.00000, 0.00000>;              
vector cvMainRotClose=ZERO_VECTOR;                  
vector cvJibPos=<1.71130, 0.00000, 4.24780>;             
vector cvJibSizeOpen=<4.27706, 0.39654, 6.17853>;    
vector cvJibSizeClose=<4.27706, 0.01000, 0.01000>;   
vector cvJibRot=<0.00000, -21.60000, 0.00000>;                   
vector cvBoomRot=<0.00000, 0.00000, 0.00000>;
vector cvRudderRot=<0.00000, 0.00000, 0.00000>;    //rudder rest rotation
vector cvWakePos=<2.22820, -0.00001, 0.495>;  

//CURRENT CONSTANTS
float cfCurrentFactorX=0.5;
float cfCurrentFactorY=0.5;

//WAVE CONSTANTS
float cfWaveHoverMax=0.05;              //max visual wave height meters
float cfWaveMaxHeelX=200;               //50.0; //max visual wave heel degrees
float cfWaveMaxHeelY=200;               //10.0; //max visual wave pitch degrees
float cfWaveHeelAt1MeterHeight=11.0;    //degrees wave heel for 1 meter wave height.
float cfWaveSpeedClimbFactor=0.8;       //speed reduction factor when climb a wave.   0.5=half   2.0=double 
                                        //1.0=reduce 50% at 7 meters height wave for snipe (4.3m length), a larger boat the factor will be smaller 
float cfWaveSpeedDownFactor=0.8;        //speed increase factor when go down a wave.   0.5=half   2.0=double  
                                        //1.0=reduce 50% at 7 meters height wave for snipe (4.3m length), a larger boat the factor will be smaller 
float cfWaveSteerFactor=0.5;            //Steer factor when climb or descent a wave   
                          

//LINKS NUMBERS
integer giCREW;
integer giTEXTHUD;
integer giMAIN;
integer giJIB;
integer giRUDDER;
integer giBOOM;
integer giWAKE;


//GLW PARAMS  
//parameters sent by GLW Receiver one time for start, update and recovery event
string  gsEventName;
string  gsGlwDirectorName;
string  gsGlwExtra1;        
string  gsGlwExtra2;

//GLW TIMER VARIABLES
integer giCurrentDir;  
float   gfCurrentSpeed;  
integer giWaveEffects;    //0-none  1-wave steer effect  2-wave speed effect  3-both
float   gfWaveHeight;  
float   gfWaveHeightMax;
integer giWindBend;       //shadow wind effect
integer giWindDir=0;
integer giWindSpeed=15; 

//GLOBAL VARIABLES
string  gsAnimation;
string  gsAnimationBase;
integer giChannel;
float   gfExtraHeight;
key     gkHelm;
integer giHelmLink;
integer giHud;  //0-normal  1-extended1  2-extended2
integer giHudsChannel;   //<================== glw v1.2 Boat communication channel with hud. Receiver creates it and sends it to the engine
integer giListenHandle;
string  giId;
integer giNumOfPrims;
float   gfRudderSteerEffect_z;
float   gfSailAngle;
integer giSailMode;  //0-moored  1-sailing
integer giSailSide;   //-1 port    1 Stb  
float   gfSeaLevel;
integer giWindMode;      //0-mywind/cruising   1-glw     2-racing 
vector  gvWindVector=<.0,9.0,.0>;  //wind from north, 9 m/s 

//GLOBAL CONTROL VARIABLES
float   gfCtrlTimer; //Control event local var for SetTimerEvent
integer giInvert; //0-tiller    1-rudder    //<==== v1.11  invert command and mouselook
integer giCrr=CONTROL_ROT_RIGHT;        //<==== v1.11  invert command and mouselook
integer giCrl=CONTROL_ROT_LEFT;        //<==== v1.11  invert command and mouselook
integer giCmr=CONTROL_RIGHT;            //<==== v1.11  invert command and mouselook
integer giCml=CONTROL_LEFT;             //<==== v1.11  invert command and mouselook
integer giVCrr;    //<==== v1.11  invert command and mouselook
integer giVCrl;     //<==== v1.11  invert command and mouselook
integer giVCtl;    //<==== v1.11  invert command and mouselook

//GLOBAL TIMER VARIABLES
rotation    grBoatRot;
vector      gvHeading;
vector      gvLeft;
vector      gvVelocity;         //vector boat velocity m/s
float       gfSpeed;             //boat speed in m/s 
vector      gvApparentWind;               //vector Aparent Wind  radians
vector      gvNormalApparentWind;              //Normalized vector Aparent Wind radians
vector      gvAxis;              //up or down axis to turn sail around
float       gfApparentWindAngle;           //apparent wind, local angle [0;PI] radians
float       gfTWA;               //Real Wind Angle radians
integer     giHead;            //heading degrees
rotation    grSailRot;
float       gfSetsail;           //final value of the angle of rotation of the sail radians
vector      gvSailnormal;       //value of the vector normal to the sail in global coordinates
vector      gvAction;           //value of the action of the wind on the boat 
integer     giSwhead;
integer     giHeadobj;
float       gfSoundWind=5.0158;

//GLOBAL SAIL TIMER VARIABLES
float gfSailSpeedEffect_x;
float gfSailHeelEffect_x;

//GLOBAL CURRENT TIMER VARIABLES
float   gfCurrentSpeedEffect_x;
float   gfCurrentSpeedEffect_y;

//GLOBAL WAVE TIMER VARIABLES
integer giWaveSign;
float   gfWaveHeightPrev;
integer giSwSound;   //0 no sound   1 sail sound    2 up wave    3 down wave
integer giSwSoundOld;
float   gfWaveHeelBoatY;     //pitch applied to the boat 
float   gfWaveHeelBoatX;     //heel applied to the boat 
float   gfWaveSpeedEffect_x;
float   gfWaveSteerEffect_z;

//GLOBAL BOAT TIMER VARIABLES
vector  gvTemp;             //temporal var vector
float   gfTotalHeelX;     //=heel for sails + heel for waves    radians
float   gfMovZ;
vector  gvAngular_motor;
vector  gvLinear_motor;
string  gsTextHud;
vector  gvTextHudColor;            //color hud
string  gvTextHudSymbol;     //color symbol
float   gfBurstrate;
float   gfBurstspeed;
string  gsSymbol;
string  gsWindMode; 

//LOCAL SAIL TIMER VARIABLES
float gfSailEfficiancy;
float gfAngle;
float gfSignSailWind;

//LOCAL CURRENT TIMER VARIABLES
float   gfCurrentAngle;  //angle between heading and current direction
vector  gvCurrentVelocity;  ////current velocity

//LOCAL WAVE TIMER VARIABLES
float   gfWaveHeightx1;
float   gfWaveHeelMaxX;
float   gfWaveHeelMaxY;
float   gfwaveHeelMax;
string  gsWaveBoatPosSymbol;    //Hud Symbol up or down wave
string  gsWaveBoatHeelSymbol;   //Hud Symbol inclination wave
float   gfWaveBoatPos;       //height of the boat in the wave 
float   gfWaveSpeedEffectX;
float   gfSteerEffect;
float   gfWaveHeelX;
float   gfWaveHeelY;

vector angle2Vector(integer piAngle, integer piVel)
{
    while(piAngle>180) piAngle-=360;
    return(<llSin(piAngle*DEG_TO_RAD),llCos(piAngle*DEG_TO_RAD),0.0>*piVel*cfKt2Ms);
}

getLinkNums() 
{
    integer liI;
    integer liLinkCount=llGetNumberOfPrims();
    string lsStr;
    for (liI=1;liI<=liLinkCount;++liI) {
        lsStr=llGetLinkName(liI);
        if (lsStr=="crew") giCREW=liI;
        else if (lsStr=="texthud") giTEXTHUD=liI;
        else if (lsStr=="main") giMAIN=liI;
        else if (lsStr=="jib") giJIB=liI;
        else if (lsStr=="rudder") giRUDDER=liI;
        else if (lsStr=="boom") giBOOM=liI;
        else if (lsStr=="wake") giWAKE=liI;
    }
}

setVehicleParams()
{ 
    llSetVehicleType(VEHICLE_TYPE_BOAT);
    llSetVehicleFlags(VEHICLE_FLAG_HOVER_GLOBAL_HEIGHT);
    llSetVehicleFloatParam(VEHICLE_BANKING_EFFICIENCY, 0.0 );
    llSetVehicleFloatParam(VEHICLE_ANGULAR_MOTOR_TIMESCALE, 0.65); // default 4
    llSetVehicleFloatParam(VEHICLE_LINEAR_DEFLECTION_EFFICIENCY, 0); // default 0.5
    llSetVehicleFloatParam(VEHICLE_LINEAR_DEFLECTION_TIMESCALE, 0); // default 3
    llSetVehicleFloatParam(VEHICLE_ANGULAR_DEFLECTION_EFFICIENCY, 1); // default 0.5   <==== currents poner a 0
    llSetVehicleFloatParam(VEHICLE_ANGULAR_DEFLECTION_TIMESCALE, 1); // default 5
    llSetVehicleFloatParam(VEHICLE_HOVER_HEIGHT,llWater(ZERO_VECTOR)+cfFloatLevel);
    llSetVehicleFloatParam(VEHICLE_HOVER_EFFICIENCY,2.0);
    llSetVehicleFloatParam(VEHICLE_HOVER_TIMESCALE,1.0);
    llSetVehicleFloatParam(VEHICLE_BANKING_EFFICIENCY,0.0);
    llSetVehicleFloatParam(VEHICLE_BANKING_MIX,0.8);
    llSetVehicleFloatParam(VEHICLE_BANKING_TIMESCALE,1.0);
}

onRaise()
{
    setVehicleParams();
    // raise sails
    llSetLinkPrimitiveParamsFast(giMAIN,[PRIM_SIZE,cvMainSizeOpen,PRIM_POS_LOCAL,cvMainPosOpen, PRIM_ROT_LOCAL,llEuler2Rot(cvMainRotOpen*DEG_TO_RAD),PRIM_COLOR,2,<1.0,1.0,1.0>,1.0]);
    llSetLinkPrimitiveParamsFast(giJIB,[PRIM_SIZE,cvJibSizeOpen,PRIM_COLOR,2,<1.0,1.0,1.0>,1.0]);
    // set status
    llSetStatus( STATUS_PHYSICS | STATUS_BLOCK_GRAB | STATUS_BLOCK_GRAB_OBJECT, TRUE);     //*****
    
    // set sails to default angles
    gfSailAngle=cfMinSail;
    
    //set personal wind & sail mode
    giSailMode=1;
    llMessageLinked(LINK_THIS, MSGTYPE_SAILING, "glw", "");
    
    //init timer vars
    giSailSide=0;
    gfCurrentSpeedEffect_x=0.0;
    gfCurrentSpeedEffect_y=0.0;
    gfWaveHeight=0.0;
    gfWaveHeightMax=0.0;
    llSetTimerEvent(0.6);  //start timer
    
    // play raise sound
    llPlaySound(gsSoundRaise,1.0);

    // set animation
    llSetLinkPrimitiveParamsFast(giHelmLink,[
        PRIM_POS_LOCAL, <0, .275, .025>,
        PRIM_ROT_LOCAL,llEuler2Rot(<20.0, 0.0, 0.0>*DEG_TO_RAD)
    ]);
    llStopAnimation(gsAnimation);
    gsAnimation=gsAnimationBase;
    llStartAnimation(gsAnimation);
}

onMoor(integer pi)
{
    //kill timer vars
    llSetTimerEvent(0.0);

    // reset vehicle type
    llSetVehicleType(VEHICLE_TYPE_NONE);
    // set status
    llSetStatus(STATUS_PHYSICS | STATUS_BLOCK_GRAB | STATUS_BLOCK_GRAB_OBJECT, FALSE);
    
    //set personal wind & sail mode
    giSailMode=0;
    llMessageLinked(LINK_THIS, MSGTYPE_MOORED, "glw", "");              

    // turn off particles
    setParticles(0);
    
    // set boat moored position
    setMooredPos();  
    list la=llGetPrimitiveParams([PRIM_ROT_LOCAL,PRIM_POSITION]);
    vector lvVec=llRot2Euler((rotation)llList2String(la,0));
    vector lvPos=(vector)llList2String(la,1);
    lvPos.z=cfPosZ;
    llSetLinkPrimitiveParamsFast(LINK_ROOT,[PRIM_ROT_LOCAL,llEuler2Rot(<0,0,lvVec.z>),PRIM_POSITION,lvPos]); 
    llSetLinkPrimitiveParamsFast(giTEXTHUD,[PRIM_TEXT,"",<1,1,1>,0.0]);
    if(pi==1) {
        llPlaySound(gsSoundLower,1.0);
        llSetLinkPrimitiveParamsFast(giHelmLink,[
            PRIM_POS_LOCAL, <0, .475, .1>,
            PRIM_ROT_LOCAL,llEuler2Rot(<10.0, 0.0, 0.0>*DEG_TO_RAD)
        ]);
        llStopAnimation(gsAnimation);
        gsAnimation=gsAnimation="steer moored L";
        llStartAnimation(gsAnimation);
    }
    else llStopSound();
    giSwSound=giSwSoundOld=0;
}

onHelp() {
    llOwnerSay("
            Boat commands:
                moor                ~ docks the boat
                raise               ~ start sailing
                winddir             ~ set personal wind direction *number
                windspeed           ~ set personal wind speed *number
                mywind or cruising  ~ subscribe to personal wind or glw cruising wind
                glw                 ~ set glw wind mode
                racing              ~ subscribe to racing wind
                worldwind           ~ subscribe to world wind *not yet enabled
                recovery            ~ recover glw wind
                windinfo            ~ print wind info
                cam                 ~ reset camera to default for this boat
                hud                 ~ toggle hud modes
                channel             ~ set boat channel *number 
                id                  ~ set boat id for racing
                boatreset           ~ reset boat scripts
                invert              ~ invert steering controls
                help                ~ print help
            ");
}

setMooredPos()
{
    llSetLinkPrimitiveParamsFast(giMAIN,[PRIM_SIZE,cvMainSizeClose,PRIM_POS_LOCAL,cvMainPosClose,
        PRIM_ROT_LOCAL,llEuler2Rot(cvMainRotClose*DEG_TO_RAD),PRIM_COLOR,ALL_SIDES,<1.0,1.0,1.0>,0.0]);
    llSetLinkPrimitiveParamsFast(giJIB,[PRIM_SIZE,cvJibSizeClose,PRIM_POS_LOCAL,cvJibPos,
        PRIM_ROT_LOCAL,llEuler2Rot(cvJibRot*DEG_TO_RAD),PRIM_COLOR,ALL_SIDES,<1.0,1.0,1.0>,0.0]);
    llSetLinkPrimitiveParamsFast(giRUDDER,[PRIM_ROT_LOCAL,llEuler2Rot(cvRudderRot*DEG_TO_RAD)]);
    llSetLinkPrimitiveParamsFast(giBOOM,[PRIM_ROT_LOCAL,llEuler2Rot(cvBoomRot*DEG_TO_RAD)]);
}

initialize(integer piMode)
{
    // set text hud
    llSetLinkPrimitiveParamsFast(giTEXTHUD,[PRIM_TEXT,"",<1,1,1>,1.0]);
    
    //set initial position
    gfSeaLevel=llWater(ZERO_VECTOR);
    vector lvPos=llGetPos();
    vector lvRot=llRot2Euler(llGetRot());
    llSetRot(llEuler2Rot(<0,0,lvRot.z>));
    
    //if over water, set boat height to sealevel;
    if (llGround(ZERO_VECTOR)<= gfSeaLevel) {
        lvPos.z=gfSeaLevel+cfFloatLevel;
        while (llVecDist(llGetPos(),lvPos)>.001) llSetPos(lvPos);
    }
    llSetLinkPrimitiveParamsFast(giWAKE,[PRIM_ROT_LOCAL,ZERO_ROTATION,PRIM_POS_LOCAL,cvWakePos]);

    // moor boat
    onMoor(0);

    //set personal wind & sail mode
    giWindMode=0;
    llMessageLinked(LINK_THIS, MSGTYPE_MYWIND, "glw", "");

    gfSailAngle=cfMinSail;
    
    if(piMode==0){//from state_entry
        integer n=llGetNumberOfPrims()-llGetObjectPrimCount(llGetKey());
        if(n>0) sitHelm();   //sit helm
        if(n>1) llMessageLinked(LINK_THIS,0,"crewport","");
        // glw update boat parameters for shadow wind + switch send params to hud
        llMessageLinked(LINK_THIS, MSGTYPE_BOATPARAMS, "glw", (string)sailArea+","+boatLength2Bow+","+boatLength2Stern+",1");        
    }

    giSwSound=giSwSoundOld=0;

    llOwnerSay("The boat is ready mode:" + (string)piMode);
}

sitHelm()
{
    key lkAvi=llAvatarOnLinkSitTarget(LINK_ROOT);
    if(lkAvi){
        if(gkHelm) return;
        else
        {
            if(lkAvi==llGetOwner()){
                gkHelm=lkAvi;
                giHelmLink=llGetNumberOfPrims();
                llSetLinkPrimitiveParamsFast(giHelmLink,[
                    PRIM_POS_LOCAL, <0, .475, .1>,
                    PRIM_ROT_LOCAL, llEuler2Rot(<10.0, 0.0, 0.0>*DEG_TO_RAD)
                ]);
                gsAnimationBase="steer sit L";
                gsAnimation="steer moored L";
                // if(giHelmLink>0) llSetLinkPrimitiveParamsFast(giHelmLink,[PRIM_POS_LOCAL, <0, .275, .025>]);
                // llSetLinkPrimitiveParamsFast(giHelmLink,[PRIM_ROT_LOCAL,llEuler2Rot(<20.0, 0.0, 0.0>*DEG_TO_RAD)]);
                // gsAnimationBase="steer sit L";
                // gsAnimation=gsAnimationBase;
                llRequestPermissions(gkHelm, PERMISSION_TAKE_CONTROLS | PERMISSION_TRIGGER_ANIMATION | PERMISSION_CONTROL_CAMERA);
            }
            else llSay(0,"Only the owner can skipper the boat");
        }
    }
    else
    {
        // unsit helm
        if(gkHelm)
        {
            llSetTimerEvent(0.0);
            llReleaseControls();
            llListenRemove(giListenHandle);
            onMoor(0);
            gkHelm=""; 
            giHelmLink=0;
        }
    }
}

setCamera()
{
    llClearCameraParams(); // reset camera to default
    llSetCameraParams(
        [
            CAMERA_ACTIVE, 1, // 1 is active, 0 is inactive
            CAMERA_BEHINDNESS_ANGLE, 0.0, // (0 to 180) degrees
            CAMERA_BEHINDNESS_LAG, 0.0, // (0 to 3) seconds
            CAMERA_DISTANCE, 6.5, // ( 0.5 to 10) meters
            CAMERA_FOCUS_LAG, 0.05, // 0.05 , // (0 to 3) seconds
            CAMERA_FOCUS_LOCKED, FALSE, // (TRUE or FALSE)
            CAMERA_FOCUS_THRESHOLD, 0.0, // (0 to 4) meters
            CAMERA_PITCH, 15.0, // (-45 to 80) degrees\
            CAMERA_POSITION_LAG, 0.0, // (0 to 3) seconds
            CAMERA_POSITION_LOCKED, FALSE, // (TRUE or FALSE)
            CAMERA_POSITION_THRESHOLD, 0.0 // (0 to 4) meters 
        ]
    );
}

setWindShadow()
{
    if(gfApparentWindAngle>0) gfApparentWindAngle-=giWindBend*DEG_TO_RAD;
    else gfApparentWindAngle+=giWindBend*DEG_TO_RAD;
}

setSailRotation()
{
    if(gfApparentWindAngle>gfSailAngle) 
    {
        gfSetsail=gfSailAngle;
    }
    else 
    {
        gfSetsail=gfApparentWindAngle;
    }
    grSailRot = llAxisAngle2Rot(<.0,.0,gvAxis.z>,gfSetsail);
    gvSailnormal = llRot2Left(grSailRot)*grBoatRot;
    if((grSailRot.z<0.0 && giSailSide<0) || (grSailRot.z>0.0 && giSailSide>0))
    {  //the sail is on correct tack
        llSetLinkPrimitiveParamsFast( giMAIN, [PRIM_ROT_LOCAL, grSailRot*llEuler2Rot(cvMainRotOpen*DEG_TO_RAD)]);
        llSetLinkPrimitiveParamsFast( giJIB, [PRIM_ROT_LOCAL, grSailRot*llEuler2Rot(cvJibRot*DEG_TO_RAD)]);
    }
    else if(grSailRot.z<0.0) 
    {   //change sails side starboard
        giSailSide=-1;
        llSetLinkPrimitiveParamsFast( giMAIN, [PRIM_ROT_LOCAL, grSailRot*llEuler2Rot(cvMainRotOpen*DEG_TO_RAD),
            PRIM_COLOR,1,<1.0,1.0,1.0>,0.0,PRIM_COLOR,2,<1.0,1.0,1.0>,1.0]);
        llSetLinkPrimitiveParamsFast( giJIB, [PRIM_ROT_LOCAL, grSailRot*llEuler2Rot(cvJibRot*DEG_TO_RAD),
            PRIM_COLOR,1,<1.0,1.0,1.0>,0.0,PRIM_COLOR,2,<1.0,1.0,1.0>,1.0]);
    }
    else if(grSailRot.z>0.0) 
    {  //change the sail side port
        giSailSide=1;
        llSetLinkPrimitiveParamsFast( giMAIN, [PRIM_ROT_LOCAL, grSailRot*llEuler2Rot(cvMainRotOpen*DEG_TO_RAD),
            PRIM_COLOR,1,<1.0,1.0,1.0>,1.0,PRIM_COLOR,2,<1.0,1.0,1.0>,0.0]);
        llSetLinkPrimitiveParamsFast( giJIB, [PRIM_ROT_LOCAL, grSailRot*llEuler2Rot(cvJibRot*DEG_TO_RAD),
            PRIM_COLOR,1,<1.0,1.0,1.0>,1.0,PRIM_COLOR,2,<1.0,1.0,1.0>,0.0]);
    }
    llSetLinkPrimitiveParamsFast(giBOOM,[PRIM_ROT_LOCAL, grSailRot*llEuler2Rot(cvBoomRot*DEG_TO_RAD)]);   //set boom
}

setParticles(integer toggle)
{
    if(toggle)
    {
        // optional particles
        gfBurstrate = 5.0/(20.0*gfSpeed+1.0);
        gfBurstspeed = 0.3*gfSpeed;
        gvTemp=llRot2Euler(ZERO_ROTATION/grBoatRot);
        gvTemp.z=0;
        gvTemp.y-=25;
        llSetLinkPrimitiveParamsFast(giWAKE,[
            PRIM_ROT_LOCAL,llEuler2Rot(gvTemp)*ZERO_ROTATION,
            PRIM_POS_LOCAL,<cvWakePos.x,cvWakePos.y,cvWakePos.z-gfExtraHeight>
        ]);   
                
        llLinkParticleSystem(giWAKE, [
            PSYS_PART_FLAGS , 0
            | PSYS_PART_INTERP_COLOR_MASK       //Colors fade from start to end
            | PSYS_PART_INTERP_SCALE_MASK       //Scale fades from beginning to end
            ,
            PSYS_SRC_PATTERN,            PSYS_SRC_PATTERN_ANGLE_CONE
            ,PSYS_SRC_TEXTURE,           "b1b5356d-9c40-e3a7-70ec-c32066f531f6"                 //UUID of the desired particle texture, or inventory name
            ,PSYS_SRC_MAX_AGE,           0.0                //Time, in seconds, for particles to be emitted. 0 = forever
            ,PSYS_PART_MAX_AGE,          7.0               //Lifetime, in seconds, that a particle lasts
            ,PSYS_SRC_BURST_RATE,        gfBurstrate          //How long, in seconds, between each emission
            ,PSYS_SRC_BURST_PART_COUNT,  100                //Number of particles per emission
            ,PSYS_SRC_BURST_RADIUS,      .05                //Radius of emission
            ,PSYS_SRC_BURST_SPEED_MIN,   gfBurstspeed         //Minimum speed of an emitted particle
            ,PSYS_SRC_BURST_SPEED_MAX,   gfBurstspeed*1.1     //Maximum speed of an emitted particle
            ,PSYS_SRC_ACCEL,             <.0,.0,-.1>        //Acceleration of particles each second
            ,PSYS_PART_START_COLOR,      <1.0,1.0,1.0>      //Starting RGB color
            ,PSYS_PART_END_COLOR,        <0.3,0.4,0.5>      //Ending RGB color, if INTERP_COLOR_MASK is on
            ,PSYS_PART_START_ALPHA,      1.0                //Starting transparency, 1 is opaque, 0 is transparent.
            ,PSYS_PART_END_ALPHA,        0.0                //Ending transparency
            ,PSYS_PART_START_SCALE,      <0.8,0.10,0.0>     //Starting particle size
            ,PSYS_PART_END_SCALE,        <1.5,0.05,0.0>     //Ending particle size, if INTERP_SCALE_MASK is on
            ,PSYS_SRC_ANGLE_BEGIN,       1.62               //Inner angle for ANGLE patterns
            ,PSYS_SRC_ANGLE_END,         1.62               //Outer angle for ANGLE patterns
            ,PSYS_SRC_OMEGA,             <0.0,0.0,0.0>      //Rotation of ANGLE patterns, similar to llTargetOmega()
        ]);
    }
    else
    {
        llLinkParticleSystem(giWAKE,[]);
    }
}

setHUD() {

    // optional signal color
    if(gfSailAngle < 0.435*gfApparentWindAngle)
    { 
        gvTextHudColor=cvBlue;
        gvTextHudSymbol="<>";
    }
    else if(gfSailAngle < 0.565*gfApparentWindAngle)
    {
        gvTextHudColor=cvGreen;
        gvTextHudSymbol="==";
    }
    else if(gfSailAngle < 0.825*gfApparentWindAngle)
    { 
        gvTextHudColor=cvYellow;
        gvTextHudSymbol="><";
    }
    else
    { 
        gvTextHudColor=cvRed;
        gvTextHudSymbol=">><<";
    }  

    // set wind mode strings for hud
    if(giWindMode==0) gsWindMode="Personal ";
    else if(giWindMode==1) gsWindMode="Cruise ";
    else if(giWindMode==2) gsWindMode="Race "; 

    gsTextHud="HDG: "+(string)giHead+"º  SPD: "+llGetSubString((string)(gfSpeed/cfKt2Ms),0,3)+"kt HEEL: "+(string)llAbs(llRound(gfTotalHeelX*RAD_TO_DEG))+"º\n"
    +gsWindMode+" TWD: "+(string)giWindDir+"º TWA: "+(string)llRound(gfTWA*RAD_TO_DEG)+"º TWS: "+(string)giWindSpeed+"kt\n"
    +"AWA: "+(string)llRound(gfApparentWindAngle*RAD_TO_DEG)+"º  SHEET: "+(string)llRound(gfSailAngle*RAD_TO_DEG)+"º";

    llSetLinkPrimitiveParamsFast(giTEXTHUD,[PRIM_TEXT,gsTextHud,gvTextHudColor,1.0]);
}

setSound()
{
    if(gfSpeed<0.257) llStopSound();   //<.5kt in m/s
    else if(gfSpeed>=0.257 && gfSpeed<2.572) llLoopSound(gsSoundSailSlow, 1); //.5kt in m/s <> 5kt in m/s
    else if(gfSpeed>=2.572 && gfSpeed<4.63) llLoopSound(gsSoundSailFast, 1); //5kt in m/s <> 9kt in m/s
    else if((gfSpeed>=4.63)) llLoopSound(gsSoundSailPlane, 1); //>9kt in m/s
}

onGLWMsg(integer num, string id)
{
    if(num==MSGTYPE_GLWPARAMS) 
    {                           
        //<================== glw. You receive the glw wind parameters every second
        list laParams=llCSV2List((string)id);
        giWindDir=(integer)llList2String(laParams,0);   //degrees
        giWindSpeed=(integer)llList2String(laParams,1);  //kt
        giCurrentDir=(integer)llList2String(laParams,2);  //degrees
        gfCurrentSpeed=(float)llList2String(laParams,3);  //kt
        gfWaveHeight=(float)llList2String(laParams,4);    //meters
        gfWaveHeightMax=(float)llList2String(laParams,5);  //meters
        giWaveEffects=(integer)llList2String(laParams,6);  //0-no effects  1-steer effect  2-speed effect  3-speed & steer effects
        giWindBend=(integer)llList2String(laParams,7);      //shadow effect        
        gvWindVector=angle2Vector(giWindDir,giWindSpeed);   //calc wind vector
        gfSoundWind=giWindSpeed*cfKt2Ms*0.7;   //----->the boat maximum speed m/s. Is 65% of the wind speed (depending on the boat)
        if(gfWaveHeightMax>0) gfExtraHeight=gfWaveHeight*cfWaveHoverMax/gfWaveHeightMax;  //calc hover height produced by the waves
        else gfExtraHeight=0.0;
        

    }
    else if(num==MSGTYPE_GLWINITIALIZE) 
    {               
        //<================== glw. You receive it when wind are started, updated or recovery
        list laParams=llCSV2List((string)id);
        integer liType=(integer)llList2String(laParams,0);   //0-started  1-recovery  2-updated
        gsEventName=llList2String(laParams,1);
        gsGlwDirectorName=llList2String(laParams,2);
        gsGlwExtra1=llList2String(laParams,3);
        gsGlwExtra2=llList2String(laParams,4);
        if(liType==1) giWindMode=(integer)llList2String(laParams,5);  //for recovery save windMode
        giHudsChannel=llList2Integer(laParams,6);     //<================== glw v1.2 Receive Hud's Channel from Script Receiver
    }
}

default
{
    state_entry()
    {
        llResetOtherScript("Crew");
        llMessageLinked(LINK_THIS, MSGTYPE_RESET, "glw", "");           //<================== glw. Reset "GLW Receiver" script
        llSetStatus( STATUS_PHYSICS | STATUS_BLOCK_GRAB | STATUS_BLOCK_GRAB_OBJECT, FALSE);
        giNumOfPrims=llGetObjectPrimCount(llGetKey());
        cfThreeDEG = cfThreeDEG*DEG_TO_RAD;    //converts deg to radians
        cfOneDEG = cfOneDEG*DEG_TO_RAD;    //converts deg to radians
        cfMaxSail = cfMaxSail*DEG_TO_RAD;  //converts deg to radians
        cfMinSail = cfMinSail*DEG_TO_RAD;  //converts deg to radians
        integer liSitTarget;
        for(liSitTarget=1;liSitTarget<=giNumOfPrims;liSitTarget++) llLinkSitTarget(liSitTarget,ZERO_VECTOR,ZERO_ROTATION);   
        getLinkNums();
        llLinkSitTarget(LINK_ROOT,<-1.6, 0.6, 1.05>,ZERO_ROTATION);    //set sittarget for helm
        if(giCREW>0) llLinkSitTarget(giCREW,<-1.2, 0.0, 0.25>,ZERO_ROTATION);   //set sittarget for crew 
        giChannel=0;
        initialize(0); 
        llOwnerSay("\nBoat initialized...\nLet's rock and roll!"); 
    }
    
    on_rez( integer p){ 
        initialize(1);
    }
    
    touch_start(integer num_detected)
    {
        string lsWindMode;
        if(gkHelm){
            if(giWindMode==0) lsWindMode="Personal Wind=>";
            else if(giWindMode==1) lsWindMode="Cruise Wind=>";
            else if(giWindMode==2) lsWindMode="Race Wind=>";
            lsWindMode+=" DIR: "+(string)giWindDir+"º SPD: "+(string)giWindSpeed+"kt";
        }else{
            lsWindMode="Moored";
        }
        llInstantMessage(llDetectedKey(0), llGetDisplayName(llGetOwner())+": "+lsWindMode);
    }    
    
    listen(integer piChannel, string psName, key pkId, string psMsg)
    {
        if (psMsg=="raise") 
        {
            onRaise();
        }
        else if (psMsg=="moor") 
        {
            onMoor(1);
        }
        else if (psMsg=="mywind" || psMsg=="cruising")
        { 
            //for personal wind
            giWindMode=0;
            gfWaveHeightMax=0.0;
            gfCurrentSpeed=0.0;
             //set personal wind mode
            llMessageLinked(LINK_THIS, MSGTYPE_MYWIND, "glw", "");
        }
        else if(llGetSubString(psMsg,0,2)=="glw")
        {
            //<==== v1.12 The glw command can take a parameter exam: glw tyccruise 
            if(giWindMode==0){
                //set glw cruise wind mode
                giWindMode=1;   //for cruise
                llMessageLinked(LINK_THIS, MSGTYPE_GLWIND, "glw", psMsg);//<================== glw glw wind mode for cruise. v1.12 add psMsg parameter
            }else{
                llOwnerSay(csMsgChangeWind);
            }
        }
        else if(llGetSubString(psMsg,0,5)=="racing")
        {      
            //<==== v1.12 The racing command can take a parameter exam: racing b22race  
            if(giWindMode==0){
                //set glw race wind mode
                giWindMode=2;  //for race
                llMessageLinked(LINK_THIS, MSGTYPE_RACING, "glw", psMsg); //<================== glw race wind mode for racing. v1.12 add psMsg parameter
            }else{
                llOwnerSay(csMsgChangeWind);
            }
        }
        else if (psMsg=="worldwind")
        {
            if(giWindMode==0){
                giWindMode=3;  //for world wind, to sailing
                llMessageLinked(LINK_THIS, MSGTYPE_WORLDWIND, "glw", ""); //<================== glw world wind mode NO IMPLEMENTED
            }else{
                llOwnerSay(csMsgChangeWind);
            }
        }
        else if(psMsg=="recovery")
        { 
            llMessageLinked(LINK_THIS, MSGTYPE_RECOVERY, "glw", ""); //<================== glw recovery command to recover the wind after a crash
        }
        else if(psMsg=="windinfo")
        { 
            llMessageLinked(LINK_THIS, MSGTYPE_WINDINFO, "glw", ""); //<================== glw info command to print settings in chat
        }
        else if(psMsg=="cam")
        { 
            if(llGetPermissions() & PERMISSION_CONTROL_CAMERA) setCamera();
            else llOwnerSay("You do not have permissions to reset the camera");
        }
        else if (psMsg=="hud")
        { 
            if(giHud==2) giHud=0;
            else giHud++;
        }
        else if(llGetSubString(psMsg,0,7)=="channel ")
        { 
            giChannel=(integer)llGetSubString(psMsg,7,-1);
            if(gkHelm){ 
                llListenRemove(giListenHandle);
                giListenHandle=llListen(giChannel, "", gkHelm, "");
            }
            llOwnerSay("Your channel is: "+(string)giChannel);
        }
        else if (llGetSubString(psMsg,0,2)=="id ")
        {
            giId=llGetSubString(psMsg,3,-1);
            if(gkHelm){ 
                llSetLinkPrimitiveParamsFast(LINK_ROOT, [PRIM_NAME, llGetObjectName()+" #"+giId]);
            }
            llOwnerSay("Your id is: "+(string)giId);
        }
        else if(psMsg=="boatreset")
        { 
            llResetScript();
        }
        else if(psMsg=="invert")
        {        
            //v1.11  invert command and mouselook
            giInvert=!giInvert;
            if(giInvert){
                giCrr=CONTROL_ROT_LEFT;
                giCrl=CONTROL_ROT_RIGHT;
                giCmr=CONTROL_LEFT;
                giCml=CONTROL_RIGHT; 
            }else{
                giCrr=CONTROL_ROT_RIGHT;
                giCrl=CONTROL_ROT_LEFT;
                giCmr=CONTROL_RIGHT;
                giCml=CONTROL_LEFT; 
            }
        }
        else if(psMsg=="help")
        { 
            onHelp();
        }
        else if(giWindMode==0) 
        {
            if (llGetSubString(psMsg,0,6)=="winddir") {  //personal wind direction
                integer liN=(integer)llGetSubString(psMsg,7,-1);
                if (liN>=0 || liN<=359) { 
                    giWindDir=liN;      
                    gvWindVector=angle2Vector(giWindDir,giWindSpeed); 
                } 
            }
            else if (llGetSubString(psMsg,0,8)=="windspeed") 
            {  //personal wind speed
                integer liN=(integer)llGetSubString(psMsg,9,-1);
                if(liN>=5 || liN<=30) {     
                    giWindSpeed=liN;      
                    gvWindVector=angle2Vector(giWindDir,giWindSpeed); 
                    gfSoundWind=giWindSpeed*cfKt2Ms*0.7;   //----->the boat maximum speed m/s. Is 65% of the wind speed (depending on the boat)
                } 
            }
        }
    } 
    
    link_message(integer sender_num, integer num, string str, key id) 
    {
        if(str=="glw") onGLWMsg(num, id);
    }            
    
    changed(integer piChange)
    {
        if (piChange & CHANGED_LINK) sitHelm();
    }
    
    run_time_permissions(integer perm)
    {
        if ( perm & PERMISSION_TRIGGER_ANIMATION ) {
            list laAnims=llGetAnimationList(gkHelm);    
            integer liN=llGetListLength(laAnims);
            integer liI; 
            if(llGetAgentSize(gkHelm)){   ´
                for(liI=0;liI<liN;liI++){
                    if((key)llList2String(laAnims,liI)) llStopAnimation(llList2String(laAnims,liI));
                }
            }   
            giListenHandle=llListen(giChannel, "", gkHelm, "");
            llStartAnimation(gsAnimation);            
        }
        if ( perm & PERMISSION_TAKE_CONTROLS ) llTakeControls(
            CONTROL_FWD |
            CONTROL_BACK |
            CONTROL_UP |
            CONTROL_DOWN |
            CONTROL_ROT_RIGHT |
            CONTROL_ROT_LEFT |
            CONTROL_LEFT |
            CONTROL_RIGHT,
            TRUE,
            FALSE
        );
        if ( perm & PERMISSION_CONTROL_CAMERA ) setCamera();
    }
    
    control(key id, integer level, integer edge)
    {
        if(giSailMode==0) return;   
        if(edge & level & (CONTROL_FWD | CONTROL_BACK | CONTROL_UP | CONTROL_DOWN | CONTROL_LEFT | CONTROL_RIGHT)){
            if(edge & level & CONTROL_FWD) // ease sail 3 deg
            {
                if(gfSailAngle+cfThreeDEG < cfMaxSail) gfSailAngle+=cfThreeDEG;
                else gfSailAngle=cfMaxSail;
            }
            else if(edge & level & CONTROL_BACK) // trim sail 3 deg
            {
                if(gfSailAngle-cfThreeDEG > cfMinSail) gfSailAngle-=cfThreeDEG;
                else gfSailAngle=cfMinSail;
            }
            else if(edge & level & CONTROL_UP) // ease sail 1 deg 
            {
                if(gfSailAngle+cfOneDEG < cfMaxSail) gfSailAngle+=cfOneDEG;
                else gfSailAngle=cfMaxSail;
            }
            else if(edge & level & CONTROL_DOWN) // trim sail 1 deg
            {
                if(gfSailAngle-cfOneDEG > cfMinSail) gfSailAngle-=cfOneDEG;
                else gfSailAngle=cfMinSail;
            }
            else if(edge & level & CONTROL_LEFT)
            {
                //change sailors side
                if(gkHelm==llGetLinkKey(giNumOfPrims+1)) giHelmLink=giNumOfPrims+1;
                else if(gkHelm==llGetLinkKey(giNumOfPrims+2)) giHelmLink=giNumOfPrims+2;
                else giHelmLink=0;
                if(giHelmLink>0) {
                    llSetLinkPrimitiveParamsFast(giHelmLink,[
                        PRIM_POS_LOCAL, <0, .275, .025>,
                        PRIM_ROT_LOCAL,llEuler2Rot(<20.0, 0.0, 0.0>*DEG_TO_RAD)
                    ]);
                }
                gsAnimationBase="steer sit L";
                llStopAnimation(gsAnimation);
                gsAnimation=gsAnimationBase;
                llStartAnimation(gsAnimation);
            }
            else if(edge & level & CONTROL_RIGHT)
            {
                //change sailors side
                if(gkHelm==llGetLinkKey(giNumOfPrims+1)) giHelmLink=giNumOfPrims+1;
                else if(gkHelm==llGetLinkKey(giNumOfPrims+2)) giHelmLink=giNumOfPrims+2;
                else giHelmLink=0;
                if(giHelmLink>0)
                {
                    llSetLinkPrimitiveParamsFast(
                        giHelmLink,[
                            PRIM_POS_LOCAL, <0, -.275, .025>,
                            PRIM_ROT_LOCAL,llEuler2Rot(<-20.0, 0.0, 0.0>*DEG_TO_RAD)
                    ]);
                }
                gsAnimationBase="steer sit R";
                llStopAnimation(gsAnimation);
                gsAnimation=gsAnimationBase;
                llStartAnimation(gsAnimation);
            }
            llSetTimerEvent(0.05);
            return;
        }
        
        if (!(llGetAgentInfo(gkHelm) & AGENT_MOUSELOOK))
        {    
            //it's not in mouselook //<==== v1.11  invert command and mouselook
            giVCtl=CONTROL_ROT_RIGHT | CONTROL_ROT_LEFT;
            giVCrr=giCrr;     //<==== v1.11  invert command and mouselook
            giVCrl=giCrl;    //<==== v1.11  invert command and mouselook
        }
        else
        {
            giVCtl=CONTROL_RIGHT | CONTROL_LEFT;  //it is in mouselook  //<==== v1.11  invert command and mouselook
            giVCrr=giCmr;    //<==== v1.11  invert command and mouselook
            giVCrl=giCml;    //<==== v1.11  invert command and mouselook
        }

        if(edge & giVCtl)
        {  
            //left or right keys helm. raise and leave state swstate>1
            gfCtrlTimer=0.05;
            float lfHealFactor;
            if(edge & level & giVCrr) 
            {    
                //right    //<==== v1.11  invert command and mouselook
                gfRudderSteerEffect_z=(.7+(gfSpeed/100)); // .7 + give turn rate a speed bonus
                llSetLinkPrimitiveParamsFast(giRUDDER,[PRIM_ROT_LOCAL, llEuler2Rot(<0,0,-21>*DEG_TO_RAD)]);
                llSetVehicleVectorParam  (VEHICLE_LINEAR_FRICTION_TIMESCALE,<100.0,0.05,0.5>);
            } 
            else if(edge & level & giVCrl) 
            {  
                //left      //<==== v1.11  invert command and mouselook
                gfRudderSteerEffect_z=-(.7+(gfSpeed/100)); // .7 + give turn rate a speed bonus
                llSetLinkPrimitiveParamsFast(giRUDDER,[PRIM_ROT_LOCAL, llEuler2Rot(<0,0,21>*DEG_TO_RAD)]);
                llSetVehicleVectorParam  (VEHICLE_LINEAR_FRICTION_TIMESCALE,<100.0,0.05,0.5>);
            } 
            else if(edge & giVCtl) 
            {   
                //up arrow key
                gfRudderSteerEffect_z=0.0;
                llSetLinkPrimitiveParamsFast(giRUDDER,[PRIM_ROT_LOCAL, llEuler2Rot(<0,0,0>*DEG_TO_RAD)]);
                llSetVehicleVectorParam  (VEHICLE_LINEAR_FRICTION_TIMESCALE,<100.0,100.0,0.5>);
                gvAngular_motor.z=gfRudderSteerEffect_z;
                llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, gvAngular_motor);  //stops turning
                gfCtrlTimer=1.0;  //wait for it to finish spinning
            }
            llSetTimerEvent(gfCtrlTimer);
        }
    }
    
    timer()
    {
        if (llGetStatus(STATUS_PHYSICS)) {
            llSetTimerEvent(0.0);
            grBoatRot = llGetRot();
            gvHeading = llRot2Fwd(grBoatRot);
            gvLeft = llRot2Left(grBoatRot);
            gvVelocity = llGetVel();
            gvApparentWind = gvWindVector + gvVelocity;
            gvApparentWind.z = 0.0;
            gvNormalApparentWind = llVecNorm(gvApparentWind);
            gvAxis = gvHeading%gvNormalApparentWind; //up or down axis to turn sail around
            gfApparentWindAngle = llAcos(gvHeading*gvNormalApparentWind); //apparent wind, local angle [0;PI] radians
            gfTWA=llAcos(gvHeading*llVecNorm(gvWindVector)); //real wind angle, local angle [0;PI] radians
            
            //shadow wind affects the angle of the apparent wind
            if(giWindBend>0) setWindShadow();
    
            //adjust sail rotation and side of boat
            setSailRotation();
            
            //calc sails speed and heel effects
            if(llFabs(gvSailnormal*gvNormalApparentWind)>=cfMinSail)
            {
                if(gvAxis.z<0) 
                {
                    gvAction=llVecMag(gvApparentWind)*gvSailnormal;
                }
                else 
                {
                    gvAction=-llVecMag(gvApparentWind)*gvSailnormal;
                }   
                
                //efficiency calc
                if(gfSailAngle==0)
                { 
                    gfSailEfficiancy=0;
                }
                else
                { 
                    if(llFabs(gfSetsail-gfApparentWindAngle)<0.087)
                    {  // >5º boat in irons
                        gfSailEfficiancy=0;
                    }
                    else if(gfApparentWindAngle>2.96705973)
                    {   // >170º boat sailing by the lee
                        gfAngle=gfSetsail+PI_BY_TWO;  //angle optimum wind perpendicular to the sail
                        gfSailEfficiancy=(gfAngle-llFabs(gfApparentWindAngle-gfAngle))/gfAngle;  //sail efficiency
                    }
                    else
                    {   //wind less than 90 degrees
                        //optimum sail angle
                        gfAngle=(gfApparentWindAngle*RAD_TO_DEG)/2;
                        gfSignSailWind=(gfSetsail*RAD_TO_DEG)-gfAngle; 
                        if(llFabs(gfSignSailWind)<1.0) gfSignSailWind=0.0;   
                        //sail efficiency 
                        gfSailEfficiancy=(gfAngle-llFabs(gfSignSailWind))/gfAngle;
                        if(gfSailEfficiancy<0) 
                        {
                            gfSailEfficiancy=0;
                        }  
                        else if(gfApparentWindAngle<0.52)
                        {  //wind <30º
                            gfSailEfficiancy=gfSailEfficiancy*(gfApparentWindAngle/0.52);
                        }
                        else if(gfSailEfficiancy>0.96)
                        {   //max efficiency
                            //if optimal angle <30 and dif <0.04 efi=1 
                            if(gfAngle<30) 
                            {
                                gfSailEfficiancy=1.0;
                            }
                            //if angle >=30 and dif<0.02 efi=1
                            else if(gfSailEfficiancy>0.98) 
                            {
                                gfSailEfficiancy=1.0;
                            }
                        }
                    }
                }
                
            }
            else
            { 
                gvAction=ZERO_VECTOR;
            }
            
            gfSailSpeedEffect_x = cfSailFactor*gvAction*gvHeading*gfSailEfficiancy;   //sail speed effect 
            gfSailHeelEffect_x = -cfHeelFactor*gvAction*gvLeft*gfSailEfficiancy;          //sail heel effect
            giHead=llRound(llAtan2(gvHeading.x,gvHeading.y)*RAD_TO_DEG);  //global heading in degrees
            if(giHead<0) giHead+=360;
            else if(giHead>359) giHead-=360;
            
            //<====== SETTING SAIL AND SAILORS
            float lfPara=0.5*llPow((llFabs(gfApparentWindAngle)-PI_BY_TWO),2);
            if(gfApparentWindAngle>PI_BY_TWO) lfPara=-lfPara-lfPara*2.0*((gfApparentWindAngle-PI_BY_TWO)/PI_BY_TWO);
            else lfPara+=lfPara*4.0*(gfApparentWindAngle/PI_BY_TWO);


            //===>CALC CURRENTS AND WATERSPEED
            //input vars gfCurrentSpeed, giCurrenDir, giHead
            //output vars gfCurrentSpeedEffect_x, gfCurrentSpeedEffect_y
            //local vars gfCurrentAngle, gvCurrentVelocity
            if(gfCurrentSpeed!=0.0) 
            {
                gfCurrentAngle=(giHead-giCurrentDir+180)*DEG_TO_RAD;  //angle between heading and current direction
                gfCurrentSpeedEffect_x=llCos(gfCurrentAngle)*gfCurrentSpeed*cfKt2Ms*cfCurrentFactorX; //x-axis boat current speed
                gfCurrentSpeedEffect_y=llSin(gfCurrentAngle)*gfCurrentSpeed*cfKt2Ms*cfCurrentFactorY; //y-axis boat current speed

                //calc waterspeed
                gvCurrentVelocity=<llCos(giCurrentDir*DEG_TO_RAD),llSin(giCurrentDir*DEG_TO_RAD),0> * gfCurrentSpeed*cfKt2Ms; //current velocity
            }
            else
            {
                gfCurrentSpeedEffect_x=gfCurrentSpeedEffect_y=0;
            }

            //===>CALC WAVES
            //constants: cfWaveHeelAt1MeterHeight, cfWaveMaxHeelX, cfWaveMaxHeelY
            //input vars: gfWaveHeightMax, gfWaveHeight, gfTWA, gfWaveHeightPrev, giWaveSign, giSwSound, gfApparentWindAngle
            //output vars: gfWaveHeelX, gfWaveHeelY, gfWaveHeightPrev, giWaveSign, giSwSound, gfWaveHeelBoatY, gsWaveBoatPosSymbol
            //temporal vars: gfWaveHeightx1, gfWaveHeelMaxX, gfWaveHeelMaxY, gfwaveHeelMax, gfWaveBoatPos
            if(gfWaveHeightMax>0.0){
                gfWaveHeightx1=gfWaveHeight/gfWaveHeightMax;  //1 up, -1 down, 0 middle    0,1,0,-1,0,...   unit value of wave height
                gfWaveBoatPos=llSin(llAcos(gfWaveHeightx1));   //0-flat up or down  1-max heel in the wave middle
                gfwaveHeelMax = gfWaveHeightMax*cfWaveHeelAt1MeterHeight;  //max heel degrees
                //heel>
                gfWaveHeelMaxX = gfwaveHeelMax*llSin(gfTWA);   //max heel depending on relative real wind direction. 90 max heel wave through degrees
                gfWaveHeelX=gfWaveHeelMaxX*gfWaveBoatPos;  //heel depending of the height of the boat in the wave  degrees
                //<
                //pich>
                gfWaveHeelMaxY = llFabs(gfwaveHeelMax*llCos(gfTWA)); //max pich depending on relative real wind direction. 0/180º max pich degrees
                gfWaveHeelY=gfWaveHeelMaxY*gfWaveBoatPos;  //pich depending on wave height  degrees
                //<
                if(gfWaveHeightx1<gfWaveHeightPrev){  //the boat descend the wave 
                    gfWaveBoatPos=-gfWaveBoatPos;       //negative
                    gfWaveHeelY=-gfWaveHeelY;           //pitch
                    gfWaveHeelX=-gfWaveHeelX;
                    giWaveSign=-1;           //heel
                    giSwSound=3;  //wave down
                }else if(gfWaveHeightx1>gfWaveHeightPrev){  //the boat climb the wave
                    giWaveSign=1;
                    giSwSound=2;   //wave up
                }else if(giWaveSign==-1){  
                    gfWaveBoatPos=-gfWaveBoatPos;       //negative
                    gfWaveHeelY=-gfWaveHeelY;           //pitch
                    gfWaveHeelX=-gfWaveHeelX;
                }                
                gfWaveHeightPrev=gfWaveHeightx1;

                if(gfWaveHeelMaxY>cfWaveMaxHeelY) gfWaveHeelBoatY=-gfWaveHeelY*cfWaveMaxHeelY/gfWaveHeelMaxY;  //pich weighting
                else gfWaveHeelBoatY=-gfWaveHeelY;
                if(llFabs(gfApparentWindAngle)>120*DEG_TO_RAD) gfWaveHeelBoatY=gfWaveHeelBoatY*0.8;  // reduce the visual wave pitch effect a little when going downwind 

                if(gfWaveHeelMaxX>cfWaveMaxHeelX) gfWaveHeelBoatX=gfWaveHeelX*cfWaveMaxHeelX/gfWaveHeelMaxX;  //heel weighting
                else gfWaveHeelBoatX=gfWaveHeelX;

                //WAVE SPEED EFFECT
                //the wave reduce or increase the speed effect of the wind by a percentage
                //gfWaveHeightMax  is the max wave height of the water to the crest, i.e. the middle of the wave 
                //constants: cfWaveSpeedClimbFactor, , cfWaveSpeedDownFactor
                //input vars: giWaveEffects, gfWaveBoatPos, gfSailSpeedEffect_x, gfWaveHeight, gfWaveHeightMax, gfTWA
                //output vars: gfWaveSpeedEffect_x
                //temporal vars: gfWaveSpeedEffectX
                if(giWaveEffects>=2){  //speed effect active
                    if(llFabs(gfWaveBoatPos)<0.3){ 
                        gfWaveSpeedEffect_x=0.0;
                    }else if(gfWaveBoatPos>0){   //climb the wave
                        //when the boat is rising to 7 meters in height, the speed is reduced by 50%. 0.5/7=0.072
                        //gfWaveHeight range = -gfWaveHeightMax to gfWaveHeightMax
                        //(gfWaveHeightMax+gfWaveHeight) = 0 to gfWaveHeightMax*2  from the valley to the ridge
                        gfWaveSpeedEffectX=-(gfSailSpeedEffect_x*(gfWaveHeightMax+gfWaveHeight)*0.072*cfWaveSpeedClimbFactor);
                        //This effect increases if the boat is going with or against the REAL wind and is reduced to 0 when the boat is across the wind.
                        gfWaveSpeedEffect_x=gfWaveSpeedEffectX*llFabs(llCos(gfTWA));  //llFabs(llCos(gfTWA)) = 0 for 0,180º and 1 for 90º
                    }else if(gfWaveBoatPos<0){ //descend the wave 
                        //when the boat has descended a wave of 7 meters its speed increases by 50%. 7*0.072=0.5
                        //3*gfWaveHeightMax-gfWaveHeight = 0 to gfWaveHeightMax*2  from the ridge to the valley
                        gfWaveSpeedEffectX=gfSailSpeedEffect_x*(3*gfWaveHeightMax-gfWaveHeight)*0.072*cfWaveSpeedDownFactor;
                        //This effect increases if the boat is going with or against the REAL wind and is reduced to 0 when the boat is across the wind.
                        gfWaveSpeedEffect_x=gfWaveSpeedEffectX*llFabs(llCos(gfTWA));  //
                    }
                }else{
                    gfWaveSpeedEffect_x=0;
                }
                //END WAVE SPEED EFFECT



                //WAVE STEER EFFECT
                //When the boat goes up or down a wave it tends to cross to the direction of the wave
                //The effect is most pronounced in the middle of the wave when the boat has maximum pitch.
                //constants: cfWaveSteerFactor
                //input vars: giWaveEffects, gfWaveBoatPos, gfWaveHeightMax, gfTWA
                //output vars: gfWaveSteerEffect_z
                //temporal vars: gfSteerEffect
                if(giWaveEffects==1 || giWaveEffects==3){  //steer effect active
                    if(llFabs(gfWaveBoatPos)<0.3){ //boat is flat
                        gfSteerEffect=0.0;  //When the boat is flat the effect is 0
                    }else{   //climb or descent the wave
                        //The effect depends on the height of the wave, in the middle of the slope the greater effect
                        //gfWaveBoatPos  is the position of the boat in the wave 0-down/up 1-middle 0-up/down
                        //llCos(gfTWA) //This effect increases if the boat is going with or against the REAL wind and is reduced to 0 when the boat is across the wind.
                        gfSteerEffect = gfWaveHeightMax/7 * llFabs(gfWaveBoatPos) * llCos(gfTWA) * cfWaveSteerFactor;
                    }

                    //puts the appropriate sign depending on tack port or starboard
                    if(gvAxis.z>0) gfWaveSteerEffect_z=-gfSteerEffect;
                    else gfWaveSteerEffect_z=gfSteerEffect;
                }else{
                    gfWaveSteerEffect_z=0;
                }
                //END WAVE STEER EFFECT

                //HUD SYMBOLS                    
                if(gfWaveBoatPos>0.3) gsWaveBoatPosSymbol="/";
                else if(gfWaveBoatPos<-0.3) gsWaveBoatPosSymbol="\\";
                else gsWaveBoatPosSymbol="-";
    
                if(gfWaveBoatPos>0.3) gsWaveBoatHeelSymbol="/";
                else if(gfWaveBoatPos<-0.3) gsWaveBoatHeelSymbol="\\";
                else gsWaveBoatHeelSymbol="-";
                //END HUD SYMBOLS
            }else{
                gfWaveHeelX=gfWaveHeelY=gfWaveSpeedEffect_x=gfWaveSteerEffect_z=gfWaveHeelBoatY=gfWaveHeelBoatX=0.0;
                gsWaveBoatPosSymbol=gsWaveBoatHeelSymbol="";
                giSwSound=1; //sail
            }

            // boat wave height
            llSetVehicleFloatParam (VEHICLE_HOVER_HEIGHT, gfSeaLevel+cfFloatLevel+gfExtraHeight);

            // boat heel
            gfTotalHeelX=gfSailHeelEffect_x-gfWaveHeelBoatX*DEG_TO_RAD;
            
            //regularization of the course due to deviation due to heel and pitch
            if(gfTotalHeelX!=0 && gfWaveHeelBoatY!=0){   //when the boat is pitching and rolling we have to correct the course  
                if(gfRudderSteerEffect_z+gfWaveSteerEffect_z==0){   //if there is no change of direction produced by the rudder or the waves...
                    if(giHeadobj==-1) giHeadobj=giHead;   //after a change of course save the target heading
                    else if(giSwhead==0){    //while the head is not stabilized
                        if(giHeadobj==giHead) giSwhead=1;   //activate regularization
                        else giHeadobj=giHead;   //update target heading
                    }
                    if(giSwhead){ 
                        gfMovZ=1.5*(giHead-giHeadobj)*DEG_TO_RAD;  //if active, calc regularization Z rotation
                        if(llFabs(gfMovZ)>0.06981) gfMovZ=0;                 //<==================== added in version 1.0Beta9b
                    }
                }else{
                    giHeadobj=-1; //init stable head
                    gfMovZ=0;
                    giSwhead=0;
                }
            }else{
                gfMovZ=0;
            }
            
            // boat angular motion
            gvAngular_motor=<gfTotalHeelX,gfWaveHeelBoatY*DEG_TO_RAD,gfRudderSteerEffect_z+gfWaveSteerEffect_z+gfMovZ>;  
            llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, gvAngular_motor);
            
            // boat speed
            gvLinear_motor=<gfSailSpeedEffect_x+gfCurrentSpeedEffect_x+gfWaveSpeedEffect_x,gfCurrentSpeedEffect_y,0.0>;
            llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, gvLinear_motor);         
            
            
            // set speed to miliseconds
            gfSpeed=llVecMag(llGetVel());    //boat speed in m/s
            
            setSound();
            setHUD();
            setParticles(1);
                
            //start timer
            if(gfWaveHeightMax>0) llSetTimerEvent(1.0);
            else llSetTimerEvent(cfTime);

        } else {
            setParticles(0);
            llSetTimerEvent( 0.0);
        }
    }
}