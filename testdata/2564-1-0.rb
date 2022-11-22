def gnuplot(cv)
  cv.delete('all')
  cmx = cv.width - 2*cv.cget('border') - 2*cv.cget('highlightthickness')
  cmx = cvcget.width  if (cmx <= 1)
  cmy = cv.height - 2*cv.cget('border') - 2*cv.cget('highlightthickness')
  cmy = cvcget.height if (cmy <= 1)
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*984/1000, cmx*155/1000, cmy*893/1000,\
    'fill'=>'#1c0a1b', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*984/1000, cmx*226/1000, cmy*893/1000,\
    'fill'=>'#1c0a1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*984/1000, cmx*296/1000, cmy*893/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*984/1000, cmx*367/1000, cmy*893/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*984/1000, cmx*437/1000, cmy*893/1000,\
    'fill'=>'#1e0b1f', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*984/1000, cmx*507/1000, cmy*893/1000,\
    'fill'=>'#200c21', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*984/1000, cmx*578/1000, cmy*893/1000,\
    'fill'=>'#210d23', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*984/1000, cmx*648/1000, cmy*893/1000,\
    'fill'=>'#230e26', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*984/1000, cmx*719/1000, cmy*893/1000,\
    'fill'=>'#26102a', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*984/1000, cmx*789/1000, cmy*893/1000,\
    'fill'=>'#1c0a1b', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*893/1000, cmx*155/1000, cmy*801/1000,\
    'fill'=>'#1c0a1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*893/1000, cmx*226/1000, cmy*801/1000,\
    'fill'=>'#1c0b1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*893/1000, cmx*296/1000, cmy*801/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*893/1000, cmx*367/1000, cmy*801/1000,\
    'fill'=>'#1e0b1e', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*893/1000, cmx*437/1000, cmy*801/1000,\
    'fill'=>'#200c20', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*893/1000, cmx*507/1000, cmy*801/1000,\
    'fill'=>'#220d24', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*893/1000, cmx*578/1000, cmy*801/1000,\
    'fill'=>'#250f28', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*893/1000, cmx*648/1000, cmy*801/1000,\
    'fill'=>'#2e1639', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*893/1000, cmx*719/1000, cmy*801/1000,\
    'fill'=>'#372554', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*893/1000, cmx*789/1000, cmy*801/1000,\
    'fill'=>'#1c0a1b', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*801/1000, cmx*155/1000, cmy*710/1000,\
    'fill'=>'#1c0a1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*801/1000, cmx*226/1000, cmy*710/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*801/1000, cmx*296/1000, cmy*710/1000,\
    'fill'=>'#1d0b1e', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*801/1000, cmx*367/1000, cmy*710/1000,\
    'fill'=>'#1f0c20', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*801/1000, cmx*437/1000, cmy*710/1000,\
    'fill'=>'#210d22', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*801/1000, cmx*507/1000, cmy*710/1000,\
    'fill'=>'#250f28', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*801/1000, cmx*578/1000, cmy*710/1000,\
    'fill'=>'#2c1535', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*801/1000, cmx*648/1000, cmy*710/1000,\
    'fill'=>'#373c6f', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*801/1000, cmx*719/1000, cmy*710/1000,\
    'fill'=>'#439560', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*801/1000, cmx*789/1000, cmy*710/1000,\
    'fill'=>'#1c0a1b', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*710/1000, cmx*155/1000, cmy*618/1000,\
    'fill'=>'#1c0a1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*710/1000, cmx*226/1000, cmy*618/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*710/1000, cmx*296/1000, cmy*618/1000,\
    'fill'=>'#1e0b1e', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*710/1000, cmx*367/1000, cmy*618/1000,\
    'fill'=>'#1f0c20', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*710/1000, cmx*437/1000, cmy*618/1000,\
    'fill'=>'#220d24', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*710/1000, cmx*507/1000, cmy*618/1000,\
    'fill'=>'#2a1330', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*710/1000, cmx*578/1000, cmy*618/1000,\
    'fill'=>'#382f62', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*710/1000, cmx*648/1000, cmy*618/1000,\
    'fill'=>'#4f995a', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*710/1000, cmx*719/1000, cmy*618/1000,\
    'fill'=>'#dbc3f2', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*710/1000, cmx*789/1000, cmy*618/1000,\
    'fill'=>'#1c0a1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*618/1000, cmx*155/1000, cmy*527/1000,\
    'fill'=>'#1c0a1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*618/1000, cmx*226/1000, cmy*527/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*618/1000, cmx*296/1000, cmy*527/1000,\
    'fill'=>'#1e0b1e', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*618/1000, cmx*367/1000, cmy*527/1000,\
    'fill'=>'#200c21', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*618/1000, cmx*437/1000, cmy*527/1000,\
    'fill'=>'#240f27', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*618/1000, cmx*507/1000, cmy*527/1000,\
    'fill'=>'#35204c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*618/1000, cmx*578/1000, cmy*527/1000,\
    'fill'=>'#429461', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*618/1000, cmx*648/1000, cmy*527/1000,\
    'fill'=>'#dbc3f3', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*618/1000, cmx*719/1000, cmy*527/1000,\
    'fill'=>'#d7eaf6', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*618/1000, cmx*789/1000, cmy*527/1000,\
    'fill'=>'#1c0a1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*527/1000, cmx*155/1000, cmy*436/1000,\
    'fill'=>'#1c0a1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*527/1000, cmx*226/1000, cmy*436/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*527/1000, cmx*296/1000, cmy*436/1000,\
    'fill'=>'#1e0b1f', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*527/1000, cmx*367/1000, cmy*436/1000,\
    'fill'=>'#210d22', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*527/1000, cmx*437/1000, cmy*436/1000,\
    'fill'=>'#28112d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*527/1000, cmx*507/1000, cmy*436/1000,\
    'fill'=>'#354676', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*527/1000, cmx*578/1000, cmy*436/1000,\
    'fill'=>'#e4adda', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*527/1000, cmx*648/1000, cmy*436/1000,\
    'fill'=>'#daeef5', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*527/1000, cmx*719/1000, cmy*436/1000,\
    'fill'=>'#e2f4f4', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*527/1000, cmx*789/1000, cmy*436/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*436/1000, cmx*155/1000, cmy*344/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*436/1000, cmx*226/1000, cmy*344/1000,\
    'fill'=>'#1e0b1e', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*436/1000, cmx*296/1000, cmy*344/1000,\
    'fill'=>'#1f0c20', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*436/1000, cmx*367/1000, cmy*344/1000,\
    'fill'=>'#220d23', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*436/1000, cmx*437/1000, cmy*344/1000,\
    'fill'=>'#2b1332', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*436/1000, cmx*507/1000, cmy*344/1000,\
    'fill'=>'#2e667d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*436/1000, cmx*578/1000, cmy*344/1000,\
    'fill'=>'#d9c7f4', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*436/1000, cmx*648/1000, cmy*344/1000,\
    'fill'=>'#ddf1f5', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*436/1000, cmx*719/1000, cmy*344/1000,\
    'fill'=>'#d8ecf6', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*436/1000, cmx*789/1000, cmy*344/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*344/1000, cmx*155/1000, cmy*253/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*344/1000, cmx*226/1000, cmy*253/1000,\
    'fill'=>'#1e0b1e', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*344/1000, cmx*296/1000, cmy*253/1000,\
    'fill'=>'#1f0c20', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*344/1000, cmx*367/1000, cmy*253/1000,\
    'fill'=>'#210d23', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*344/1000, cmx*437/1000, cmy*253/1000,\
    'fill'=>'#250f28', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*344/1000, cmx*507/1000, cmy*253/1000,\
    'fill'=>'#331d47', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*344/1000, cmx*578/1000, cmy*253/1000,\
    'fill'=>'#429461', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*344/1000, cmx*648/1000, cmy*253/1000,\
    'fill'=>'#bc9b6b', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*344/1000, cmx*719/1000, cmy*253/1000,\
    'fill'=>'#549b58', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*344/1000, cmx*789/1000, cmy*253/1000,\
    'fill'=>'#1c0b1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*253/1000, cmx*155/1000, cmy*161/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*253/1000, cmx*226/1000, cmy*161/1000,\
    'fill'=>'#1d0b1e', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*253/1000, cmx*296/1000, cmy*161/1000,\
    'fill'=>'#1e0b1f', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*253/1000, cmx*367/1000, cmy*161/1000,\
    'fill'=>'#1f0c20', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*253/1000, cmx*437/1000, cmy*161/1000,\
    'fill'=>'#210d22', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*253/1000, cmx*507/1000, cmy*161/1000,\
    'fill'=>'#230e25', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*253/1000, cmx*578/1000, cmy*161/1000,\
    'fill'=>'#26102a', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*253/1000, cmx*648/1000, cmy*161/1000,\
    'fill'=>'#28112d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*253/1000, cmx*719/1000, cmy*161/1000,\
    'fill'=>'#27102b', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*253/1000, cmx*789/1000, cmy*161/1000,\
    'fill'=>'#1c0b1c', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*85/1000, cmy*161/1000, cmx*155/1000, cmy*70/1000,\
    'fill'=>'#1d0b1d', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*155/1000, cmy*161/1000, cmx*226/1000, cmy*70/1000,\
    'fill'=>'#1d0b1e', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*226/1000, cmy*161/1000, cmx*296/1000, cmy*70/1000,\
    'fill'=>'#1e0b1e', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*296/1000, cmy*161/1000, cmx*367/1000, cmy*70/1000,\
    'fill'=>'#1e0c1f', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*367/1000, cmy*161/1000, cmx*437/1000, cmy*70/1000,\
    'fill'=>'#200c21', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*437/1000, cmy*161/1000, cmx*507/1000, cmy*70/1000,\
    'fill'=>'#200d22', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*507/1000, cmy*161/1000, cmx*578/1000, cmy*70/1000,\
    'fill'=>'#210d22', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*578/1000, cmy*161/1000, cmx*648/1000, cmy*70/1000,\
    'fill'=>'#210d23', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*648/1000, cmy*161/1000, cmx*719/1000, cmy*70/1000,\
    'fill'=>'#210d22', 'outline'=>'', 'stipple'=>'')
  cr=TkcRectangle.new(cv, cmx*719/1000, cmy*161/1000, cmx*789/1000, cmy*70/1000,\
    'fill'=>'#210d22', 'outline'=>'', 'stipple'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*984/1000,\
    cmx*842/1000, cmy*984/1000,\
    cmx*842/1000, cmy*976/1000,\
    cmx*807/1000, cmy*976/1000,\
    'fill'=>'#050104', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*977/1000,\
    cmx*842/1000, cmy*977/1000,\
    cmx*842/1000, cmy*969/1000,\
    cmx*807/1000, cmy*969/1000,\
    'fill'=>'#120611', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*970/1000,\
    cmx*842/1000, cmy*970/1000,\
    cmx*842/1000, cmy*962/1000,\
    cmx*807/1000, cmy*962/1000,\
    'fill'=>'#1a0a1a', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*963/1000,\
    cmx*842/1000, cmy*963/1000,\
    cmx*842/1000, cmy*955/1000,\
    cmx*807/1000, cmy*955/1000,\
    'fill'=>'#210d22', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*956/1000,\
    cmx*842/1000, cmy*956/1000,\
    cmx*842/1000, cmy*948/1000,\
    cmx*807/1000, cmy*948/1000,\
    'fill'=>'#26102a', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*949/1000,\
    cmx*842/1000, cmy*949/1000,\
    cmx*842/1000, cmy*941/1000,\
    cmx*807/1000, cmy*941/1000,\
    'fill'=>'#2b1332', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*942/1000,\
    cmx*842/1000, cmy*942/1000,\
    cmx*842/1000, cmy*934/1000,\
    cmx*807/1000, cmy*934/1000,\
    'fill'=>'#2e1639', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*935/1000,\
    cmx*842/1000, cmy*935/1000,\
    cmx*842/1000, cmy*926/1000,\
    cmx*807/1000, cmy*926/1000,\
    'fill'=>'#311a3f', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*927/1000,\
    cmx*842/1000, cmy*927/1000,\
    cmx*842/1000, cmy*919/1000,\
    cmx*807/1000, cmy*919/1000,\
    'fill'=>'#331d47', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*920/1000,\
    cmx*842/1000, cmy*920/1000,\
    cmx*842/1000, cmy*912/1000,\
    cmx*807/1000, cmy*912/1000,\
    'fill'=>'#35214d', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*913/1000,\
    cmx*842/1000, cmy*913/1000,\
    cmx*842/1000, cmy*905/1000,\
    cmx*807/1000, cmy*905/1000,\
    'fill'=>'#362453', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*906/1000,\
    cmx*842/1000, cmy*906/1000,\
    cmx*842/1000, cmy*898/1000,\
    cmx*807/1000, cmy*898/1000,\
    'fill'=>'#372858', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*899/1000,\
    cmx*842/1000, cmy*899/1000,\
    cmx*842/1000, cmy*891/1000,\
    cmx*807/1000, cmy*891/1000,\
    'fill'=>'#382c5d', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*892/1000,\
    cmx*842/1000, cmy*892/1000,\
    cmx*842/1000, cmy*884/1000,\
    cmx*807/1000, cmy*884/1000,\
    'fill'=>'#383062', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*885/1000,\
    cmx*842/1000, cmy*885/1000,\
    cmx*842/1000, cmy*876/1000,\
    cmx*807/1000, cmy*876/1000,\
    'fill'=>'#383367', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*877/1000,\
    cmx*842/1000, cmy*877/1000,\
    cmx*842/1000, cmy*869/1000,\
    cmx*807/1000, cmy*869/1000,\
    'fill'=>'#37386b', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*870/1000,\
    cmx*842/1000, cmy*870/1000,\
    cmx*842/1000, cmy*862/1000,\
    cmx*807/1000, cmy*862/1000,\
    'fill'=>'#373c6f', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*863/1000,\
    cmx*842/1000, cmy*863/1000,\
    cmx*842/1000, cmy*855/1000,\
    cmx*807/1000, cmy*855/1000,\
    'fill'=>'#364072', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*856/1000,\
    cmx*842/1000, cmy*856/1000,\
    cmx*842/1000, cmy*848/1000,\
    cmx*807/1000, cmy*848/1000,\
    'fill'=>'#354475', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*849/1000,\
    cmx*842/1000, cmy*849/1000,\
    cmx*842/1000, cmy*841/1000,\
    cmx*807/1000, cmy*841/1000,\
    'fill'=>'#344977', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*842/1000,\
    cmx*842/1000, cmy*842/1000,\
    cmx*842/1000, cmy*834/1000,\
    cmx*807/1000, cmy*834/1000,\
    'fill'=>'#334d79', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*835/1000,\
    cmx*842/1000, cmy*835/1000,\
    cmx*842/1000, cmy*826/1000,\
    cmx*807/1000, cmy*826/1000,\
    'fill'=>'#32517b', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*827/1000,\
    cmx*842/1000, cmy*827/1000,\
    cmx*842/1000, cmy*819/1000,\
    cmx*807/1000, cmy*819/1000,\
    'fill'=>'#31567c', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*820/1000,\
    cmx*842/1000, cmy*820/1000,\
    cmx*842/1000, cmy*812/1000,\
    cmx*807/1000, cmy*812/1000,\
    'fill'=>'#305a7d', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*813/1000,\
    cmx*842/1000, cmy*813/1000,\
    cmx*842/1000, cmy*805/1000,\
    cmx*807/1000, cmy*805/1000,\
    'fill'=>'#2f5f7d', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*806/1000,\
    cmx*842/1000, cmy*806/1000,\
    cmx*842/1000, cmy*798/1000,\
    cmx*807/1000, cmy*798/1000,\
    'fill'=>'#2f637d', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*799/1000,\
    cmx*842/1000, cmy*799/1000,\
    cmx*842/1000, cmy*791/1000,\
    cmx*807/1000, cmy*791/1000,\
    'fill'=>'#2e677d', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*792/1000,\
    cmx*842/1000, cmy*792/1000,\
    cmx*842/1000, cmy*784/1000,\
    cmx*807/1000, cmy*784/1000,\
    'fill'=>'#2e6b7c', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*785/1000,\
    cmx*842/1000, cmy*785/1000,\
    cmx*842/1000, cmy*776/1000,\
    cmx*807/1000, cmy*776/1000,\
    'fill'=>'#2e6f7b', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*777/1000,\
    cmx*842/1000, cmy*777/1000,\
    cmx*842/1000, cmy*769/1000,\
    cmx*807/1000, cmy*769/1000,\
    'fill'=>'#2e737a', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*770/1000,\
    cmx*842/1000, cmy*770/1000,\
    cmx*842/1000, cmy*762/1000,\
    cmx*807/1000, cmy*762/1000,\
    'fill'=>'#2e7778', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*763/1000,\
    cmx*842/1000, cmy*763/1000,\
    cmx*842/1000, cmy*755/1000,\
    cmx*807/1000, cmy*755/1000,\
    'fill'=>'#2f7a77', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*756/1000,\
    cmx*842/1000, cmy*756/1000,\
    cmx*842/1000, cmy*748/1000,\
    cmx*807/1000, cmy*748/1000,\
    'fill'=>'#307e75', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*749/1000,\
    cmx*842/1000, cmy*749/1000,\
    cmx*842/1000, cmy*741/1000,\
    cmx*807/1000, cmy*741/1000,\
    'fill'=>'#318173', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*742/1000,\
    cmx*842/1000, cmy*742/1000,\
    cmx*842/1000, cmy*734/1000,\
    cmx*807/1000, cmy*734/1000,\
    'fill'=>'#328470', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*735/1000,\
    cmx*842/1000, cmy*735/1000,\
    cmx*842/1000, cmy*726/1000,\
    cmx*807/1000, cmy*726/1000,\
    'fill'=>'#34876e', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*727/1000,\
    cmx*842/1000, cmy*727/1000,\
    cmx*842/1000, cmy*719/1000,\
    cmx*807/1000, cmy*719/1000,\
    'fill'=>'#368a6b', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*720/1000,\
    cmx*842/1000, cmy*720/1000,\
    cmx*842/1000, cmy*712/1000,\
    cmx*807/1000, cmy*712/1000,\
    'fill'=>'#398d69', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*713/1000,\
    cmx*842/1000, cmy*713/1000,\
    cmx*842/1000, cmy*705/1000,\
    cmx*807/1000, cmy*705/1000,\
    'fill'=>'#3b8f66', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*706/1000,\
    cmx*842/1000, cmy*706/1000,\
    cmx*842/1000, cmy*698/1000,\
    cmx*807/1000, cmy*698/1000,\
    'fill'=>'#3e9264', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*699/1000,\
    cmx*842/1000, cmy*699/1000,\
    cmx*842/1000, cmy*691/1000,\
    cmx*807/1000, cmy*691/1000,\
    'fill'=>'#429461', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*692/1000,\
    cmx*842/1000, cmy*692/1000,\
    cmx*842/1000, cmy*684/1000,\
    cmx*807/1000, cmy*684/1000,\
    'fill'=>'#45965f', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*685/1000,\
    cmx*842/1000, cmy*685/1000,\
    cmx*842/1000, cmy*676/1000,\
    cmx*807/1000, cmy*676/1000,\
    'fill'=>'#49975d', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*677/1000,\
    cmx*842/1000, cmy*677/1000,\
    cmx*842/1000, cmy*669/1000,\
    cmx*807/1000, cmy*669/1000,\
    'fill'=>'#4e995a', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*670/1000,\
    cmx*842/1000, cmy*670/1000,\
    cmx*842/1000, cmy*662/1000,\
    cmx*807/1000, cmy*662/1000,\
    'fill'=>'#529a58', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*663/1000,\
    cmx*842/1000, cmy*663/1000,\
    cmx*842/1000, cmy*655/1000,\
    cmx*807/1000, cmy*655/1000,\
    'fill'=>'#579b57', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*656/1000,\
    cmx*842/1000, cmy*656/1000,\
    cmx*842/1000, cmy*648/1000,\
    cmx*807/1000, cmy*648/1000,\
    'fill'=>'#5c9c55', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*649/1000,\
    cmx*842/1000, cmy*649/1000,\
    cmx*842/1000, cmy*641/1000,\
    cmx*807/1000, cmy*641/1000,\
    'fill'=>'#619d54', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*642/1000,\
    cmx*842/1000, cmy*642/1000,\
    cmx*842/1000, cmy*634/1000,\
    cmx*807/1000, cmy*634/1000,\
    'fill'=>'#669e53', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*635/1000,\
    cmx*842/1000, cmy*635/1000,\
    cmx*842/1000, cmy*626/1000,\
    cmx*807/1000, cmy*626/1000,\
    'fill'=>'#6b9e52', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*627/1000,\
    cmx*842/1000, cmy*627/1000,\
    cmx*842/1000, cmy*619/1000,\
    cmx*807/1000, cmy*619/1000,\
    'fill'=>'#729e52', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*620/1000,\
    cmx*842/1000, cmy*620/1000,\
    cmx*842/1000, cmy*612/1000,\
    cmx*807/1000, cmy*612/1000,\
    'fill'=>'#779f51', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*613/1000,\
    cmx*842/1000, cmy*613/1000,\
    cmx*842/1000, cmy*605/1000,\
    cmx*807/1000, cmy*605/1000,\
    'fill'=>'#7d9f52', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*606/1000,\
    cmx*842/1000, cmy*606/1000,\
    cmx*842/1000, cmy*598/1000,\
    cmx*807/1000, cmy*598/1000,\
    'fill'=>'#839f52', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*599/1000,\
    cmx*842/1000, cmy*599/1000,\
    cmx*842/1000, cmy*591/1000,\
    cmx*807/1000, cmy*591/1000,\
    'fill'=>'#899e53', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*592/1000,\
    cmx*842/1000, cmy*592/1000,\
    cmx*842/1000, cmy*584/1000,\
    cmx*807/1000, cmy*584/1000,\
    'fill'=>'#8e9e54', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*585/1000,\
    cmx*842/1000, cmy*585/1000,\
    cmx*842/1000, cmy*576/1000,\
    cmx*807/1000, cmy*576/1000,\
    'fill'=>'#949e56', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*577/1000,\
    cmx*842/1000, cmy*577/1000,\
    cmx*842/1000, cmy*569/1000,\
    cmx*807/1000, cmy*569/1000,\
    'fill'=>'#9b9d58', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*570/1000,\
    cmx*842/1000, cmy*570/1000,\
    cmx*842/1000, cmy*562/1000,\
    cmx*807/1000, cmy*562/1000,\
    'fill'=>'#a09d5a', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*563/1000,\
    cmx*842/1000, cmy*563/1000,\
    cmx*842/1000, cmy*555/1000,\
    cmx*807/1000, cmy*555/1000,\
    'fill'=>'#a69d5d', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*556/1000,\
    cmx*842/1000, cmy*556/1000,\
    cmx*842/1000, cmy*548/1000,\
    cmx*807/1000, cmy*548/1000,\
    'fill'=>'#ab9c5f', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*549/1000,\
    cmx*842/1000, cmy*549/1000,\
    cmx*842/1000, cmy*541/1000,\
    cmx*807/1000, cmy*541/1000,\
    'fill'=>'#b09c63', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*542/1000,\
    cmx*842/1000, cmy*542/1000,\
    cmx*842/1000, cmy*534/1000,\
    cmx*807/1000, cmy*534/1000,\
    'fill'=>'#b59b66', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*535/1000,\
    cmx*842/1000, cmy*535/1000,\
    cmx*842/1000, cmy*526/1000,\
    cmx*807/1000, cmy*526/1000,\
    'fill'=>'#ba9b6a', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*527/1000,\
    cmx*842/1000, cmy*527/1000,\
    cmx*842/1000, cmy*519/1000,\
    cmx*807/1000, cmy*519/1000,\
    'fill'=>'#c09b6e', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*520/1000,\
    cmx*842/1000, cmy*520/1000,\
    cmx*842/1000, cmy*512/1000,\
    cmx*807/1000, cmy*512/1000,\
    'fill'=>'#c49a73', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*513/1000,\
    cmx*842/1000, cmy*513/1000,\
    cmx*842/1000, cmy*505/1000,\
    cmx*807/1000, cmy*505/1000,\
    'fill'=>'#c89a77', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*506/1000,\
    cmx*842/1000, cmy*506/1000,\
    cmx*842/1000, cmy*498/1000,\
    cmx*807/1000, cmy*498/1000,\
    'fill'=>'#cc9a7c', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*499/1000,\
    cmx*842/1000, cmy*499/1000,\
    cmx*842/1000, cmy*491/1000,\
    cmx*807/1000, cmy*491/1000,\
    'fill'=>'#d09a81', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*492/1000,\
    cmx*842/1000, cmy*492/1000,\
    cmx*842/1000, cmy*484/1000,\
    cmx*807/1000, cmy*484/1000,\
    'fill'=>'#d39a86', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*485/1000,\
    cmx*842/1000, cmy*485/1000,\
    cmx*842/1000, cmy*477/1000,\
    cmx*807/1000, cmy*477/1000,\
    'fill'=>'#d69a8b', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*478/1000,\
    cmx*842/1000, cmy*478/1000,\
    cmx*842/1000, cmy*469/1000,\
    cmx*807/1000, cmy*469/1000,\
    'fill'=>'#d99a90', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*470/1000,\
    cmx*842/1000, cmy*470/1000,\
    cmx*842/1000, cmy*462/1000,\
    cmx*807/1000, cmy*462/1000,\
    'fill'=>'#dc9b96', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*463/1000,\
    cmx*842/1000, cmy*463/1000,\
    cmx*842/1000, cmy*455/1000,\
    cmx*807/1000, cmy*455/1000,\
    'fill'=>'#de9b9c', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*456/1000,\
    cmx*842/1000, cmy*456/1000,\
    cmx*842/1000, cmy*448/1000,\
    cmx*807/1000, cmy*448/1000,\
    'fill'=>'#e09ca1', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*449/1000,\
    cmx*842/1000, cmy*449/1000,\
    cmx*842/1000, cmy*441/1000,\
    cmx*807/1000, cmy*441/1000,\
    'fill'=>'#e29da6', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*442/1000,\
    cmx*842/1000, cmy*442/1000,\
    cmx*842/1000, cmy*434/1000,\
    cmx*807/1000, cmy*434/1000,\
    'fill'=>'#e39eac', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*435/1000,\
    cmx*842/1000, cmy*435/1000,\
    cmx*842/1000, cmy*427/1000,\
    cmx*807/1000, cmy*427/1000,\
    'fill'=>'#e49fb1', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*428/1000,\
    cmx*842/1000, cmy*428/1000,\
    cmx*842/1000, cmy*419/1000,\
    cmx*807/1000, cmy*419/1000,\
    'fill'=>'#e5a0b6', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*420/1000,\
    cmx*842/1000, cmy*420/1000,\
    cmx*842/1000, cmy*412/1000,\
    cmx*807/1000, cmy*412/1000,\
    'fill'=>'#e6a2bc', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*413/1000,\
    cmx*842/1000, cmy*413/1000,\
    cmx*842/1000, cmy*405/1000,\
    cmx*807/1000, cmy*405/1000,\
    'fill'=>'#e6a3c1', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*406/1000,\
    cmx*842/1000, cmy*406/1000,\
    cmx*842/1000, cmy*398/1000,\
    cmx*807/1000, cmy*398/1000,\
    'fill'=>'#e6a5c6', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*399/1000,\
    cmx*842/1000, cmy*399/1000,\
    cmx*842/1000, cmy*391/1000,\
    cmx*807/1000, cmy*391/1000,\
    'fill'=>'#e6a6cb', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*392/1000,\
    cmx*842/1000, cmy*392/1000,\
    cmx*842/1000, cmy*384/1000,\
    cmx*807/1000, cmy*384/1000,\
    'fill'=>'#e6a8d0', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*385/1000,\
    cmx*842/1000, cmy*385/1000,\
    cmx*842/1000, cmy*377/1000,\
    cmx*807/1000, cmy*377/1000,\
    'fill'=>'#e5aad4', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*378/1000,\
    cmx*842/1000, cmy*378/1000,\
    cmx*842/1000, cmy*369/1000,\
    cmx*807/1000, cmy*369/1000,\
    'fill'=>'#e5acd8', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*370/1000,\
    cmx*842/1000, cmy*370/1000,\
    cmx*842/1000, cmy*362/1000,\
    cmx*807/1000, cmy*362/1000,\
    'fill'=>'#e4afdc', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*363/1000,\
    cmx*842/1000, cmy*363/1000,\
    cmx*842/1000, cmy*355/1000,\
    cmx*807/1000, cmy*355/1000,\
    'fill'=>'#e3b1e0', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*356/1000,\
    cmx*842/1000, cmy*356/1000,\
    cmx*842/1000, cmy*348/1000,\
    cmx*807/1000, cmy*348/1000,\
    'fill'=>'#e2b4e3', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*349/1000,\
    cmx*842/1000, cmy*349/1000,\
    cmx*842/1000, cmy*341/1000,\
    cmx*807/1000, cmy*341/1000,\
    'fill'=>'#e1b6e7', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*342/1000,\
    cmx*842/1000, cmy*342/1000,\
    cmx*842/1000, cmy*334/1000,\
    cmx*807/1000, cmy*334/1000,\
    'fill'=>'#e0b9ea', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*335/1000,\
    cmx*842/1000, cmy*335/1000,\
    cmx*842/1000, cmy*327/1000,\
    cmx*807/1000, cmy*327/1000,\
    'fill'=>'#debbec', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*328/1000,\
    cmx*842/1000, cmy*328/1000,\
    cmx*842/1000, cmy*319/1000,\
    cmx*807/1000, cmy*319/1000,\
    'fill'=>'#ddbeef', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*320/1000,\
    cmx*842/1000, cmy*320/1000,\
    cmx*842/1000, cmy*312/1000,\
    cmx*807/1000, cmy*312/1000,\
    'fill'=>'#dcc1f1', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*313/1000,\
    cmx*842/1000, cmy*313/1000,\
    cmx*842/1000, cmy*305/1000,\
    cmx*807/1000, cmy*305/1000,\
    'fill'=>'#dac4f3', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*306/1000,\
    cmx*842/1000, cmy*306/1000,\
    cmx*842/1000, cmy*298/1000,\
    cmx*807/1000, cmy*298/1000,\
    'fill'=>'#d9c6f4', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*299/1000,\
    cmx*842/1000, cmy*299/1000,\
    cmx*842/1000, cmy*291/1000,\
    cmx*807/1000, cmy*291/1000,\
    'fill'=>'#d8c9f6', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*292/1000,\
    cmx*842/1000, cmy*292/1000,\
    cmx*842/1000, cmy*284/1000,\
    cmx*807/1000, cmy*284/1000,\
    'fill'=>'#d7ccf7', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*285/1000,\
    cmx*842/1000, cmy*285/1000,\
    cmx*842/1000, cmy*277/1000,\
    cmx*807/1000, cmy*277/1000,\
    'fill'=>'#d6cff8', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*278/1000,\
    cmx*842/1000, cmy*278/1000,\
    cmx*842/1000, cmy*269/1000,\
    cmx*807/1000, cmy*269/1000,\
    'fill'=>'#d6d1f8', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*270/1000,\
    cmx*842/1000, cmy*270/1000,\
    cmx*842/1000, cmy*262/1000,\
    cmx*807/1000, cmy*262/1000,\
    'fill'=>'#d5d4f9', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*263/1000,\
    cmx*842/1000, cmy*263/1000,\
    cmx*842/1000, cmy*255/1000,\
    cmx*807/1000, cmy*255/1000,\
    'fill'=>'#d4d7f9', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*256/1000,\
    cmx*842/1000, cmy*256/1000,\
    cmx*842/1000, cmy*248/1000,\
    cmx*807/1000, cmy*248/1000,\
    'fill'=>'#d4d9f9', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*249/1000,\
    cmx*842/1000, cmy*249/1000,\
    cmx*842/1000, cmy*241/1000,\
    cmx*807/1000, cmy*241/1000,\
    'fill'=>'#d4dcf9', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*242/1000,\
    cmx*842/1000, cmy*242/1000,\
    cmx*842/1000, cmy*234/1000,\
    cmx*807/1000, cmy*234/1000,\
    'fill'=>'#d4def9', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*235/1000,\
    cmx*842/1000, cmy*235/1000,\
    cmx*842/1000, cmy*227/1000,\
    cmx*807/1000, cmy*227/1000,\
    'fill'=>'#d4e1f9', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*228/1000,\
    cmx*842/1000, cmy*228/1000,\
    cmx*842/1000, cmy*219/1000,\
    cmx*807/1000, cmy*219/1000,\
    'fill'=>'#d4e3f8', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*220/1000,\
    cmx*842/1000, cmy*220/1000,\
    cmx*842/1000, cmy*212/1000,\
    cmx*807/1000, cmy*212/1000,\
    'fill'=>'#d5e5f8', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*213/1000,\
    cmx*842/1000, cmy*213/1000,\
    cmx*842/1000, cmy*205/1000,\
    cmx*807/1000, cmy*205/1000,\
    'fill'=>'#d6e7f7', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*206/1000,\
    cmx*842/1000, cmy*206/1000,\
    cmx*842/1000, cmy*198/1000,\
    cmx*807/1000, cmy*198/1000,\
    'fill'=>'#d7e9f7', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*199/1000,\
    cmx*842/1000, cmy*199/1000,\
    cmx*842/1000, cmy*191/1000,\
    cmx*807/1000, cmy*191/1000,\
    'fill'=>'#d8ebf6', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*192/1000,\
    cmx*842/1000, cmy*192/1000,\
    cmx*842/1000, cmy*184/1000,\
    cmx*807/1000, cmy*184/1000,\
    'fill'=>'#d9edf6', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*185/1000,\
    cmx*842/1000, cmy*185/1000,\
    cmx*842/1000, cmy*177/1000,\
    cmx*807/1000, cmy*177/1000,\
    'fill'=>'#daeff5', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*178/1000,\
    cmx*842/1000, cmy*178/1000,\
    cmx*842/1000, cmy*169/1000,\
    cmx*807/1000, cmy*169/1000,\
    'fill'=>'#dcf0f5', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*170/1000,\
    cmx*842/1000, cmy*170/1000,\
    cmx*842/1000, cmy*162/1000,\
    cmx*807/1000, cmy*162/1000,\
    'fill'=>'#def2f4', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*163/1000,\
    cmx*842/1000, cmy*163/1000,\
    cmx*842/1000, cmy*155/1000,\
    cmx*807/1000, cmy*155/1000,\
    'fill'=>'#e0f3f4', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*156/1000,\
    cmx*842/1000, cmy*156/1000,\
    cmx*842/1000, cmy*148/1000,\
    cmx*807/1000, cmy*148/1000,\
    'fill'=>'#e2f5f4', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*149/1000,\
    cmx*842/1000, cmy*149/1000,\
    cmx*842/1000, cmy*141/1000,\
    cmx*807/1000, cmy*141/1000,\
    'fill'=>'#e4f6f4', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*142/1000,\
    cmx*842/1000, cmy*142/1000,\
    cmx*842/1000, cmy*134/1000,\
    cmx*807/1000, cmy*134/1000,\
    'fill'=>'#e6f7f4', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*135/1000,\
    cmx*842/1000, cmy*135/1000,\
    cmx*842/1000, cmy*127/1000,\
    cmx*807/1000, cmy*127/1000,\
    'fill'=>'#e9f8f4', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*128/1000,\
    cmx*842/1000, cmy*128/1000,\
    cmx*842/1000, cmy*119/1000,\
    cmx*807/1000, cmy*119/1000,\
    'fill'=>'#ebf9f5', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*120/1000,\
    cmx*842/1000, cmy*120/1000,\
    cmx*842/1000, cmy*112/1000,\
    cmx*807/1000, cmy*112/1000,\
    'fill'=>'#eefaf6', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*113/1000,\
    cmx*842/1000, cmy*113/1000,\
    cmx*842/1000, cmy*105/1000,\
    cmx*807/1000, cmy*105/1000,\
    'fill'=>'#f0fbf6', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*106/1000,\
    cmx*842/1000, cmy*106/1000,\
    cmx*842/1000, cmy*98/1000,\
    cmx*807/1000, cmy*98/1000,\
    'fill'=>'#f3fbf7', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*99/1000,\
    cmx*842/1000, cmy*99/1000,\
    cmx*842/1000, cmy*91/1000,\
    cmx*807/1000, cmy*91/1000,\
    'fill'=>'#f5fcf9', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*92/1000,\
    cmx*842/1000, cmy*92/1000,\
    cmx*842/1000, cmy*84/1000,\
    cmx*807/1000, cmy*84/1000,\
    'fill'=>'#f8fdfa', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*85/1000,\
    cmx*842/1000, cmy*85/1000,\
    cmx*842/1000, cmy*77/1000,\
    cmx*807/1000, cmy*77/1000,\
    'fill'=>'#fafefb', 'outline'=>'')
  cp=TkcPolygon.new(cv,\
    cmx*807/1000, cmy*78/1000,\
    cmx*842/1000, cmy*78/1000,\
    cmx*842/1000, cmy*70/1000,\
    cmx*807/1000, cmy*70/1000,\
    'fill'=>'#fdfefd', 'outline'=>'')
  cl=TkcLine.new(cv,\
    cmx*807/1000, cmy*984/1000,\
    cmx*842/1000, cmy*984/1000,\
    cmx*842/1000, cmy*70/1000,\
    cmx*807/1000, cmy*70/1000,\
    cmx*807/1000, cmy*984/1000,\
    'fill'=>'black', 'width'=>1.0, 'capstyle'=>'butt', 'joinstyle'=>'miter')
  ct=TkcText.new(cv, cmx*850/1000, cmy*984/1000,\
    'text'=>' 0', 'fill'=>'black', 'anchor'=>'w')
  ct=TkcText.new(cv, cmx*850/1000, cmy*854/1000,\
    'text'=>' 1e+07', 'fill'=>'black', 'anchor'=>'w')
  ct=TkcText.new(cv, cmx*850/1000, cmy*723/1000,\
    'text'=>' 2e+07', 'fill'=>'black', 'anchor'=>'w')
  ct=TkcText.new(cv, cmx*850/1000, cmy*593/1000,\
    'text'=>' 3e+07', 'fill'=>'black', 'anchor'=>'w')
  ct=TkcText.new(cv, cmx*850/1000, cmy*462/1000,\
    'text'=>' 4e+07', 'fill'=>'black', 'anchor'=>'w')
  ct=TkcText.new(cv, cmx*850/1000, cmy*332/1000,\
    'text'=>' 5e+07', 'fill'=>'black', 'anchor'=>'w')
  ct=TkcText.new(cv, cmx*850/1000, cmy*201/1000,\
    'text'=>' 6e+07', 'fill'=>'black', 'anchor'=>'w')
  ct=TkcText.new(cv, cmx*850/1000, cmy*70/1000,\
    'text'=>' 7e+07', 'fill'=>'black', 'anchor'=>'w')
  ct=TkcText.new(cv, cmx*437/1000, cmy*36/1000,\
    'text'=>'2564-1', 'fill'=>'black', 'anchor'=>'center')
end
def gnuplot_plotarea()
  return [85, 789, 70, 984]
end
def gnuplot_axisranges()
  return [-0.500000, 9.500000, -0.500000, 9.500000,\
          -0.500000, 9.500000, 89884656743115785407263711865852178399035283762922498299458738401578630390014269380294779316383439085770229476757191232117160663444732091384233773351768758493024955288275641038122745045194664472037934254227566971152291618451611474082904279666061674137398913102072361584369088590459649940625202013092062429184.000000, -89884656743115785407263711865852178399035283762922498299458738401578630390014269380294779316383439085770229476757191232117160663444732091384233773351768758493024955288275641038122745045194664472037934254227566971152291618451611474082904279666061674137398913102072361584369088590459649940625202013092062429184.000000]
end
