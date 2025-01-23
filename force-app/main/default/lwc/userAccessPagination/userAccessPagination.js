import { LightningElement, api } from 'lwc';
export default class PaginationComponent extends LightningElement {

    currentPage = 1;
    totalRecords;
    totalRecordsCount = 0;
    @api recordSize = 20;
    totalPage = 0;
    @api visibleRecords;
    @api hideButtonLabels = "false";
    @api firstButtonLabel = 'First';
    @api lastButtonLabel = 'Last';
    @api nextButtonLabel = 'Next';
    @api previousButtonLabel = 'Previous';
    @api totalRecordLabel = 'Total Records : ' + this.totalRecordsCount;; // Total Records : {totalRecordsCount}
    @api currentPageLabel = 'Showing ' + this.currentPage + ' of ' + this.totalPage + ' Page'; // Showing {currentPage} of {totalPage} Page
    showSpinner = false;

    // Whenever there is a change in records sent to the component, UI parameters are calculated
    get records(){
        return this.visibleRecords;
    }
    @api set records(data){
        if(data){ 
            this.totalRecords = data;
            this.totalRecordsCount = data.length;
            this.recordSize = Number(this.recordSize);
            this.totalPage = Math.ceil(data.length/this.recordSize);
            this.currentPage = 1;
            console.log('this.hideButtonLabels ', this.hideButtonLabels);
            console.log('this.recordSize >> ', this.recordSize);
            if(this.hideButtonLabels == "true"){
                this.firstButtonLabel = '';
                this.lastButtonLabel = '';
                this.nextButtonLabel = '';
                this.previousButtonLabel = '';
                this.totalRecordLabel = 'Total : ' + this.totalRecordsCount; 
                this.currentPageLabel = 'Page ' + this.currentPage + ' of ' + this.totalPage;
            }
            else{
                this.firstButtonLabel = 'First';
                this.lastButtonLabel = 'Last';
                this.nextButtonLabel = 'Next';
                this.previousButtonLabel = 'Previous';
                this.totalRecordLabel = 'Total Records : ' + this.totalRecordsCount; 
                this.currentPageLabel = 'Showing ' + this.currentPage + ' of ' + this.totalPage + ' Page';
            }
            this.updateRecords();
        }
    }

    // disabling values for First, Next, Previous and Last based on current page value
    get disablePrevious(){ 
        return this.currentPage<=1;
    }
    get disableNext(){ 
        return this.currentPage>=this.totalPage;
    }

    getCurrentPageLabel(){
        if(this.hideButtonLabels == "true"){
            this.currentPageLabel = 'Page ' + this.currentPage + ' of ' + this.totalPage;
        }
        else{
            this.currentPageLabel = 'Showing ' + this.currentPage + ' of ' + this.totalPage + ' Page';
        }
    }

    // Calculating the records to be shown on click of first, previous, next and last buttons
    firstHandler(){
        this.currentPage = 1;
        this.getCurrentPageLabel();
        this.updateRecords();
    }
    previousHandler(){ 
        if(this.currentPage>1){
            this.currentPage = this.currentPage-1;
            this.getCurrentPageLabel();
            this.updateRecords();
        }
    }
    nextHandler(){
        if(this.currentPage < this.totalPage){
            this.currentPage = this.currentPage+1;
            this.getCurrentPageLabel();
            this.updateRecords();
        }
    }
    lastHandler(){
        this.currentPage = this.totalPage;
        this.getCurrentPageLabel();
        this.updateRecords();
    }

    // Processing and slicing the records to be shown on each page 
    updateRecords(){ 
        console.log('In pagination updateRecords >>>> ');
        console.log('record size', this.recordSize);
        const start = (this.currentPage-1)*this.recordSize;
        const end = this.recordSize*this.currentPage;
        
        console.log('start >> ' + start + ' , end >> ' + end);

        this.visibleRecords = this.totalRecords.slice(start, end);
        
        let updatedRecords = [...this.visibleRecords];

        console.log('records length >> ' + updatedRecords.length + ' , JSON : ' + JSON.stringify(updatedRecords));

        this.dispatchEvent(new CustomEvent('paginationevent', { 
            detail:{ 
                slicedRecords: updatedRecords, 
                bubbles: true, 
                composed: true
            }
        }));
    }
}