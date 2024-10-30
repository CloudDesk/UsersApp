public class PartnerWsdl2ApexMockWithError implements WebServiceMock {
    public void doInvoke(
        Object stub, Object request, Map<String, Object> response,
        String endpoint, String soapAction, String requestName,
        String responseNS, String responseName, String responseType
    ) {
        throw new CalloutException('Login failed: Invalid credentials');
    }
}