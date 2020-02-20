<template>
  <div class="cosmosLedger">
    <input
      id="mainnet"
      v-model="networkChoice"
      type="radio"
      value="https://pub-rpc.maxonrow.com"
      @click="networkClick"
      :disabled="connected"
    >
    <label for="webusb">Mainnet</label>
    <input
      id="alloys"
      v-model="networkChoice"
      type="radio"
      value="https://alloys-rpc.maxonrow.com"
      @click="networkClick"
      :disabled="connected"
    >
    <label for="u2f">Alloys</label>
    <br />
    <input
      id="webusb"
      v-model="transportChoice"
      type="radio"
      value="WebUSB">
    <label for="webusb">WebUSB</label>
    <input
      id="u2f"
      v-model="transportChoice"
      type="radio"
      value="U2F"
    >
    <label for="u2f">U2F</label>    
    <br>
    <!--
        Commands
    -->
      <button 
        :disabled="connected" 
        @click="connect" >
        connect
      </button>  
        <button 
        :disabled="!connected" 
        @click="getVersion" >
          Get Version
        </button>       
    <button 
    :disabled="!connected" 
    @click="showAddress" >
      Show Address
    </button>                


 <!--
    <button 
    :disabled="!connected" 
    @click="signExampleTx">
      Sign Example TX
    </button>
   -->   
    <!--
        Commands
    -->
    <div class="form-container container">
      <div class="form-horizontal">
      <div class="form-group mb-5">
        <div class="col-sm-3">&nbsp;</div>
        <div class="col-sm-9">
          <div class="text-danger">{{ errors[0] }}</div>
        </div>
      </div>   
      <div class="form-group">
        <div class="col-sm-3">
          <label for="" class="label">chainId</label>
        </div>
        <div class="col-xs-9">
          <label for="" class="label"> {{ chainId }} </label>
        </div>
      </div>           
      <div class="form-group">
        <div class="col-sm-3">
          <label for="" class="label">From Address</label>
        </div>
        <div class="col-xs-9">
          <label for="" class="label">{{ address }} </label>
        </div>
      </div>
      <div class="form-group">
        <div class="col-sm-3">
          <label for="" class="label">balance (MXW)</label>
        </div>
        <div class="col-xs-9">
          <label for="" class="label">{{ balance }}</label>
        </div>
      </div>      
      <div class="form-group">
        <div class="col-sm-3">
          <label for="" class="label">To Address</label>
        </div>
        <div class="col-xs-9">
          <input type="text" class="form-control" v-model="form.toAddress" name="To Address" placeholder="To Address">
        </div>
      </div>
      <div class="form-group">
        <div class="col-sm-3">
          <label for="" class="label">Amount(MXW)</label>
        </div>
        <div class="col-xs-9">
          <input type="number" class="form-control" v-model="form.amount" name="Amount" placeholder="Amount">
        </div>
      </div>
       <div class="form-group">
        <div class="col-sm-3">
          <label for="" class="label">Memo</label>
        </div>
        <div class="col-xs-9">
          <input type="text" class="form-control" v-model="form.memo" name="Memo" placeholder="Memo">
        </div>
      </div>

      <div class="form-group mb-5">
        <div class="col-xs-12">
          <button type="button" class="btn btn-primary btn-lg btn-block commit-btn" @click="transfer" :disabled="transfering || !connected">Transfer</button>
        </div>
      </div>
    </div>
    </div>
     <ul id="ledger-status">
      <li
        v-for="item in ledgerStatus"
        :key="item.index"
      >
        {{ item.msg }}
      </li>
    </ul>
  </div>
</template>

<script>
// eslint-disable-next-line import/no-extraneous-dependencies
import TransportWebUSB from '@ledgerhq/hw-transport-webusb';
// eslint-disable-next-line import/no-extraneous-dependencies
import TransportU2F from '@ledgerhq/hw-transport-u2f';
import { LedgerSigner } from 'mxw-ledger-signer';
import { JsonRpcProvider } from 'mxw-sdk-js/dist/providers';
import { formatMxw, parseMxw } from 'mxw-sdk-js/dist/utils';
import { default as axios } from 'axios';


export default {
    name: 'MxwLedger',
    props: {
    },
    data() {
        return {
            errors: [],
            deviceLog: [],
            transportChoice: 'WebUSB',
            networkChoice: null,
            signer: null,
            connected: false,
            address: "",
            balance: 0,
            connecting: false,
            transfering: false,
            provider: null,
            chainId: 'N/A',
            form: {
                toAddress: '',
                amount: 0,
                memo: ''
            }
        };
    },
    computed: {
        ledgerStatus() {
            return this.deviceLog;
        },
    },
    methods: {
        log(msg) {
            this.deviceLog.push({
                index: this.deviceLog.length,
                msg,
            });
        },
        networkClick(e) {
          this.networkChoice = e.target.value;
          this.checkNetwork();
        },
        async checkNetwork() {
          var url = this.networkChoice + '/status';
          try{
            var status = await axios.get(url);
            var chainId = status.data.result.node_info.network;
            this.chainId = chainId;
            this.provider = new JsonRpcProvider(this.networkChoice,{ chainId, name: chainId  });
          }catch(error) {
            this.log(error);
          }
        
        },
        async getTransport() {
            let transport = null;

            this.log(`Trying to connect via ${this.transportChoice}...`);
            if (this.transportChoice === 'WebUSB') {
                try {
                    transport = await TransportWebUSB;
                } catch (e) {
                    this.log(e);
                }
            }

            if (this.transportChoice === 'U2F') {
                try {
                    transport = await TransportU2F;
                } catch (e) {
                    this.log(e);
                }
            }
            
            return transport;
        },
        connect(){
          this.errors=[];
            if(this.networkChoice==null || this.provider==null) {
              this.errors.push('no network selected');
              return;
            }
            this.connecting =true;
            this.getTransport().then(transport=>{
            LedgerSigner.connect(transport, this.provider).then(signer=>{
               this.signer = signer;
               this.signer.getAddress().then(async address=>{
                   if(address){
                        this.address = address;
                        this.connected = true;
                        this.connecting =false;
                        this.updateBalance();
                   }else {
                       this.log('should throw error');
                   }
               });
           });
            });
        },
        async getVersion() {
          
            this.deviceLog = [];

            // now it is possible to access all commands in the app
            const response = await this.signer.getConfig();

            this.log('Response received!');
            this.log(`App Version ${response.major}.${response.minor}.${response.patch}`);
            this.log(`Device Locked: ${response.device_locked}`);
            this.log(`Test mode: ${response.test_mode}`);
            this.log('Full response:');
            this.log(response);
        },
        async showAddress() {
            this.deviceLog = [];
            const response = await this.signer.getAddress();
            this.log(response);

            this.log('Response received!');
            this.log(`Address ${response}`);
            this.log('Full response:');
            this.log(response);
        },
        async updateBalance(){
          this.log('update balance');
            var balance = await this.provider.getBalance(this.address);
            this.balance = formatMxw(balance);
        },
        toReadableBalance(balance) {
            return formatMxw(balance);
        },
        toRawBalance(balance) {
            return parseMxw(balance +'');
        },
        async transfer() {
          var validate = this.validate();
          if(!validate)
           return false;
            this.transfering = true;
            var amount = this.toRawBalance(this.form.amount);
            var overrides = {
              memo: this.form.memo
            }
         
              this.deviceLog = [];
              this.log('begin transfer..');
              try{
              var receipt = await this.signer.transfer(this.form.toAddress, amount, overrides);
              if(receipt && receipt.hash) {
                this.log('hash: ' + receipt.hash);
                this.log('Transfer successfully');
              }
              this.log('Full response:');
              this.log(receipt);               
              }catch(error) {
                  this.log('error occur');
                   this.log(error);
              } 
             this.transfering = false;
        },
        validate() {
          this.errors = [];
          if(this.form.toAddress==''){
            this.errors.push('address is required');
            return false;
          }

          if(this.form.amount == '' || this.form.amount <=0){
            this.errors.push('Invalid amount');
            return false;             
          }
          return true;
        }
    },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
    h3 {
        margin: 40px 0 0;
    }

    button {
        padding: 5px;
        font-weight: bold;
        font-size: medium;
    }

    ul {
        padding: 10px;
        text-align: left;
        alignment: left;
        list-style-type: none;
        background: black;
        font-weight: bold;
        color: greenyellow;
    }

    .form-container {
        width: 500px !important;
    }

    .label {
      color: black
    }
</style>
