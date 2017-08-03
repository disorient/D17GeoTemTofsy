public void createSequence() {
  int fpm = fps * 60;  // Frames-per-minute

  StructurePixelMap allStructures = new StructurePixelMap(pixelMap);

  mp = new Moonpaper(this);
  Cel cel0 = mp.createCel(width, height);

  // Start of sequence
  mp.seq(new ClearCels());
  mp.seq(new PushCel(cel0, pixelMap));
  mp.seq(new PatchSet(cel0.getTransparency(), 0.0));

  // Fade in cel
  mp.seq(new PatchSet(cel0.getTransparency(), 0.0));
  mp.seq(new Line(5 * fps, cel0.getTransparency(), 255));

  //mp.seq(new PushCel(cel0, new StripSweep(pixelMap, allStructures)));
  mp.seq(new PushCel(cel0, new Plasma(pixelMap, allStructures)));
  //mp.seq(new PushCel(cel0, new BoxTest(pixelMap, allStructures)));
  mp.seq(new Wait(5*fpm));
}