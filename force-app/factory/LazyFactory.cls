public without sharing virtual class LazyFactory {
  private static final Map<String, Instance> CACHED_INSTANCES = new Map<String, Instance>();

  public interface Instance {
  }

  public Instance load(String typeName) {
    return this.load(this.getTypeFromName(typeName, ''));
  }

  public Instance load(String typeName, String namespace) {
    return this.load(this.getTypeFromName(typeName, namespace));
  }

  public Instance load(Type type) {
    Instance possibleInstance = CACHED_INSTANCES.get(type.getName());
    if (possibleInstance == null) {
      possibleInstance = (Instance) type.newInstance();
      CACHED_INSTANCES.put(type.getName(), possibleInstance);
    }
    return possibleInstance;
  }

  private Type getTypeFromName(String typeName, String possibleNamespace) {
    return Type.forName(possibleNamespace, typeName);
  }
}
