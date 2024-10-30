public interface ServiceInterface {
    Object execute(String actionMethodName, Object actionVariable);
    //Object invokeMethod(ServiceClass.ActionMethod actionMethod, Object actionVariable);
    Object invokeMethod(String actionMethod, Object actionVariable);
}