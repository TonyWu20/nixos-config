{ ... }: {
  fileSystems = {
    "/export/castep_jobs" = {
      device = "10.0.0.2:/castep_jobs";
      fsType = "nfs";
    };
    "/export/g16" = {
      device = "10.0.0.2:/g16";
      fsType = "nfs";
    };
    "/export/gauss_shell" = {
      device = "10.0.0.2:/gauss_shell";
      fsType = "nfs";
    };
    "/export/gaussian_jobs" = {
      device = "10.0.0.2:/gaussian_jobs";
      fsType = "nfs";
    };
    "/export/Potentials" = {
      device = "10.0.0.2:/Potentials";
      fsType = "nfs";
    };
  };
}
