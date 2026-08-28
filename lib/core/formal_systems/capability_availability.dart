enum CapabilityStatus { supported, experimental, unavailable, legacyOnly }

sealed class CapabilityAvailability {
  const CapabilityAvailability();

  CapabilityStatus get status;

  bool get isEnabled =>
      status == CapabilityStatus.supported ||
      status == CapabilityStatus.experimental;
}

final class SupportedCapability extends CapabilityAvailability {
  const SupportedCapability();

  @override
  CapabilityStatus get status => CapabilityStatus.supported;
}

final class ExperimentalCapability extends CapabilityAvailability {
  const ExperimentalCapability();

  @override
  CapabilityStatus get status => CapabilityStatus.experimental;
}

final class UnavailableCapability extends CapabilityAvailability {
  const UnavailableCapability();

  @override
  CapabilityStatus get status => CapabilityStatus.unavailable;
}

final class LegacyOnlyCapability extends CapabilityAvailability {
  const LegacyOnlyCapability();

  @override
  CapabilityStatus get status => CapabilityStatus.legacyOnly;
}
