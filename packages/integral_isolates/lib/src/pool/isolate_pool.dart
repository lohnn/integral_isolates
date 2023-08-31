abstract class IsolatePool {
  const IsolatePool();
}

final class IsolatePools {
  const IsolatePools._();

  static const IsolatePool newIsolate = _NewIsolatePool();
  static const IsolatePool io = _StaticIsolatePool();
  static const IsolatePool network = _NetworkIsolatePool();
}

class _NewIsolatePool extends IsolatePool {
  const _NewIsolatePool();
}

class _StaticIsolatePool extends IsolatePool {
  const _StaticIsolatePool();
}

class _NetworkIsolatePool extends IsolatePool {
  const _NetworkIsolatePool();
}
