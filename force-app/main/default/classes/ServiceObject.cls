public class ServiceObject {
    public List<Object> resultList {get; set;}
    public Object resultObject {get;set; }
    public String resultMessage {get;set; }
    
    public ServiceObject(){
        resultList = new List<Object>();
        resultMessage = '';
    }
}