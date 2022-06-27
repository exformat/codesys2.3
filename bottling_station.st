PROGRAM PLC_PRG

VAR RETAIN
	rOutProgress : REAL;
	iInputTargetMilliLiters : UINT;
	iInputImpulsePerLiter : REAL;
END_VAR

VAR
(*===input===*)
	xInputTickSensor : BOOL;
	xInputButtonStart : BOOL;
	xInputButtonStop : BOOL;

(*===output===*)
	xOutRelayOnPump : BOOL;
	xOutRelayOpenValve10mm : BOOL;
	xOutRelayOpenValve3mm : BOOL;
	xOutLedGreen : BOOL;
	xOutLedRed : BOOL;

(*===work variables===*)
	c_timDelayPostOff : TIME := T#5s;
	udiImpulseCounter : UINT;
	wImpulseTarget : WORD;
	xInWork : BOOL;
	xDelayPostOff : BOOL;
	rSensorStep : REAL;

(*===work functions===*)
	CTU_ImpulseCounter : CTU;
	TOF_DelayPostOffTimer : TOF;
	fun_pressStop: BOOL;
END_VAR

(*===========================================================================================================*)
IF xInputButtonStart AND NOT xDelayPostOff AND NOT xInWork THEN
	rSensorStep := 1000.0 / iInputImpulsePerLiter;
	wImpulseTarget :=  REAL_TO_WORD(iInputTargetMilliLiters / rSensorStep);

	IF iInputTargetMilliLiters > 200 THEN
		xOutRelayOpenValve10mm := TRUE;
		xOutRelayOpenValve3mm := FALSE;
	ELSE
		xOutRelayOpenValve3mm := TRUE;
		xOutRelayOpenValve10mm := FALSE;
	END_IF

	xOutRelayOnPump := TRUE;
	xOutLedGreen := TRUE;
	xInWork := TRUE;
END_IF

CTU_ImpulseCounter(CU:= xInputTickSensor, RESET:= NOT xInWork, PV:= wImpulseTarget);
rOutProgress := CTU_ImpulseCounter.CV * rSensorStep;

IF CTU_ImpulseCounter.Q AND xInWork THEN
	xOutRelayOnPump := FALSE;
	xOutLedGreen := FALSE;
	xOutLedRed := TRUE;
	xOutRelayOpenValve3mm := FALSE;
	xOutRelayOpenValve10mm := FALSE;
	xInWork := FALSE;
	xDelayPostOff := TRUE;
	rOutProgress := 0;
	CTU_ImpulseCounter.RESET := TRUE;
END_IF

TOF_DelayPostOffTimer(IN := xDelayPostOff, PT := c_timDelayPostOff);
xOutLedRed := TOF_DelayPostOffTimer.Q;

IF TOF_DelayPostOffTimer.Q AND xDelayPostOff THEN
	xDelayPostOff := FALSE;
END_IF

IF xInputButtonStop AND xInWork AND NOT xDelayPostOff THEN
	xOutRelayOnPump := FALSE;
	xOutLedGreen := FALSE;
	xOutRelayOpenValve3mm := FALSE;
	xOutRelayOpenValve10mm := FALSE;
	xInWork := FALSE;
	xDelayPostOff := TRUE;
	xOutLedRed := TRUE;
END_IF
