final Map<String, String> _memoryStorage = {};

String? getStorageItem(String key) => _memoryStorage[key];

void setStorageItem(String key, String value) {
  _memoryStorage[key] = value;
}

void clearStorage() {
  _memoryStorage.clear();
}
