import 'capability_availability.dart';

enum FormalSystemCapability {
  editing,
  simulation,
  analysis,
  trace,
  examples,
  help,
  session,
}

final class FormalSystemCapabilities {
  const FormalSystemCapabilities({
    this.editing = const UnavailableCapability(),
    this.simulation = const UnavailableCapability(),
    this.analysis = const UnavailableCapability(),
    this.trace = const UnavailableCapability(),
    this.examples = const UnavailableCapability(),
    this.help = const UnavailableCapability(),
    this.session = const UnavailableCapability(),
  });

  final CapabilityAvailability editing;
  final CapabilityAvailability simulation;
  final CapabilityAvailability analysis;
  final CapabilityAvailability trace;
  final CapabilityAvailability examples;
  final CapabilityAvailability help;
  final CapabilityAvailability session;

  CapabilityAvailability availabilityOf(FormalSystemCapability capability) =>
      switch (capability) {
        FormalSystemCapability.editing => editing,
        FormalSystemCapability.simulation => simulation,
        FormalSystemCapability.analysis => analysis,
        FormalSystemCapability.trace => trace,
        FormalSystemCapability.examples => examples,
        FormalSystemCapability.help => help,
        FormalSystemCapability.session => session,
      };

  bool supports(FormalSystemCapability capability) =>
      availabilityOf(capability).isEnabled;
}
