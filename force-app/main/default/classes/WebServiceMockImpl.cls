// This class acts as a Mock class for MetadataServiceTest
public class WebServiceMockImpl implements WebServiceMock 
	{
		public void doInvoke(
			Object stub, Object request, Map<String, Object> response,
			String endpoint, String soapAction, String requestName,
			String responseNS, String responseName, String responseType) 
		{
            if(request instanceof MetadataService.Retrieve_element){
                MetadataService.RetrieveResponse_element retrieveRespone = new MetadataService.RetrieveResponse_element();
                MetadataService.AsyncResult asynResult = new MetadataService.AsyncResult();
                asynResult.done = true;
                asynResult.message = 'Success';
				retrieveRespone.result = asynResult;
				response.put('response_x', retrieveRespone);
            }
            else if(request instanceof MetadataService.CheckDeployStatus_element){
                MetadataService.CheckDeployStatusResponse_element checkDeployStatusResult = new MetadataService.CheckDeployStatusResponse_element();
                MetadataService.DeployResult deployResult = new MetadataService.DeployResult();
                deployResult.canceledByName = 'Test User';
                deployResult.checkOnly = true;
                checkDeployStatusResult.result = deployResult;
                response.put('response_x', checkDeployStatusResult);
            }				
            else if(request instanceof MetadataService.listMetadata_element){
                MetadataService.ListMetadataResponse_element response_x = new MetadataService.ListMetadataResponse_element();
                List<MetadataService.FileProperties> fileProperties = new List<MetadataService.FileProperties>();
                MetadataService.FileProperties fileProp = new MetadataService.FileProperties();
                fileProp.fileName = 'Test File Name';
                fileProperties.add(fileProp);
                response_x.result = fileProperties;
				response.put('response_x',response_x);
            }
			else if(request instanceof MetadataService.checkRetrieveStatus_element)
				response.put('response_x', new MetadataService.checkRetrieveStatusResponse_element());
            else if(request instanceof MetadataService.describeMetadata_element){
                MetadataService.DescribeMetadataResponse_element describeMetadataResult = new MetadataService.DescribeMetadataResponse_element();
                MetadataService.DescribeMetadataResult describeMetadataRes = new MetadataService.DescribeMetadataResult();
                describeMetadataRes.organizationNamespace = 'TestOrganizationNameSpace';
                describeMetadataResult.result = describeMetadataRes;
                response.put('response_x',describeMetadataResult);
            }
			else if(request instanceof MetadataService.deploy_element)
				response.put('response_x', new MetadataService.deployResponse_element());
            else if(request instanceof MetadataService.updateMetadata_element)
                response.put('response_x', new MetadataService.updateMetadataResponse_element());
            else if(request instanceof MetadataService.renameMetadata_element)
                response.put('response_x', new MetadataService.renameMetadataResponse_element());
            else if(request instanceof  MetadataService.cancelDeploy_element)
                response.put('response_x', new MetadataService.cancelDeployResponse_element());
            else if(request instanceof  MetadataService.deleteMetadata_element){
                MetadataService.DeleteMetadataResponse_element response_x = new MetadataService.DeleteMetadataResponse_element();
                MetadataService.DeleteResult deleteResult = new MetadataService.DeleteResult();
                deleteResult.fullName = 'TestDeleteName';
                response_x.result = new List<MetadataService.DeleteResult>{deleteResult};
                response.put('response_x', response_x);
            }
            else if(request instanceof  MetadataService.upsertMetadata_element){
                MetadataService.upsertMetadataResponse_element response_x = new MetadataService.UpsertMetadataResponse_element();
                MetadataService.UpsertResult upsertRes = new MetadataService.UpsertResult();
                upsertRes.fullName = 'TestUpsertName';
                response_x.result = new List<MetadataService.UpsertResult>{upsertRes};
                response.put('response_x', response_x);
            }
            else if(request instanceof  MetadataService.createMetadata_element){
                MetadataService.CreateMetadataResponse_element response_x = new MetadataService.CreateMetadataResponse_element();
                MetadataService.SaveResult createRes = new MetadataService.SaveResult();
                createRes.fullName = 'TestCreateName';
                response_x.result = new List<MetadataService.SaveResult>{createRes};
                response.put('response_x', response_x);
            }
            else if(request instanceof  MetadataService.DeployRecentValidation_element)
                response.put('response_x', new MetadataService.DeployRecentValidationResponse_element());
            else if(request instanceof MetadataService.describeValueType_element)
                response.put('response_x', new MetadataService.describeValueTypeResponse_element());
			return;
		}
	}