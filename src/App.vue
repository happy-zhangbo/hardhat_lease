<template>
  <div class="common-layout">
    <el-container>
      <el-main style="line-height: 40px;">
        Connect Wallet Address：{{ signer }}<br /><br />
        NFT Contract<br />
        <el-button @click="devClaim">devClaim</el-button>
        <el-button @click="ownerOf">ownerOf</el-button><br />
        NFT Token ID：{{ tokenId }}<br />
        NFT Owner: {{ nftOwner }}
        <br /><br />
        EntrustedRental Contract<br />
        <el-button @click="approve">approve EntrustedRental Contract</el-button>
        <el-button @click="entrustedRental">EntrustedRental</el-button>
        <el-button @click="getRentalInfo">GetRentalInfo</el-button>
        <br />
        NFT Rental Info: <br />
        Owner: {{ rentalInfo.owner }}<br />
        Price: {{ rentalInfo.price }}<br />
        UserOf: {{ rentalInfo.userOf }}
        <br /><br />
        Gold Token Contract: <br />
        <el-button @click="setMintRoleAdmin">Set Mint Role Admin</el-button>
        <el-button @click="authorizeMintRole">Authorize Mint Role</el-button>
        <el-button @click="mintGold">Mint Gold</el-button>
        <el-button @click="goldTransfer">Gold Transfer 10000</el-button>
        <br />
        My Gold: {{ tokenBalance }}<br />
        AdminRole: {{ adminRole }}<br />
        MintRole: {{ mintRole }}
        <br />
        <el-button @click="depositToken">Deposit 1000 Gold Token</el-button>
        <el-button @click="leaseNFTbyPrepaid">NFT Prepaid</el-button>
        <el-button @click="getLeaseInfo">GetLeaseInfo</el-button>
        <br />
        My Margin: {{ marginBalance }}<br />
        Owner: {{ leaseInfo.owner }}<br />
        Expires: {{ leaseInfo.expires }}<br />
        Agreement: {{ leaseInfo.agreement }}<br />
        User: {{ leaseInfo.user }}
        <br /><br />
        Lease Agreement Contract: <br />
        <el-button @click="exchangeGoldToken">Exchange 10 Gold Token</el-button>
        <el-button @click="getRepaidToken">Get Repaid Token</el-button>
        <br />
        Repaid Token: {{ repaid }}
        <br />
      </el-main>
    </el-container>
  </div>
</template>

<script>
import nftAbi from "@/abi/GameItems.json";
import goldAbi from "@/abi/GoldToken.json";
import leaseAbi from "@/abi/LeaseNFT.json";
import agreementAbi from "@/abi/LeaseAgreement.json";

import { ethers } from 'ethers';
import { ElMessage, ElMessageBox } from 'element-plus'
const provider = new ethers.providers.Web3Provider(window.ethereum);
export default {
  name: 'App',
  data() {
    return {
      nftContract: null,
      goldContract: null,
      leaseContract: null,
      agreementContract: null,
      signer: null,
      nftOwner: null,
      tokenBalance: 0,
      tokenId: -1,
      rentalInfo: {},
      leaseInfo: {},
      adminRole: false,
      mintRole: false,
      marginBalance: 0,
      repaid: 0
    }
  },
  async created(){
    await provider.send("eth_requestAccounts", []);
    const signer = provider.getSigner();
    this.provider = provider;
    this.signer = signer.provider.provider.selectedAddress;
    const nftContract = new ethers.Contract(process.env.VUE_APP_NFT_CONTRACT, nftAbi.abi, provider);
    this.nftContract = nftContract.connect(signer);

    const goldContract = new ethers.Contract(process.env.VUE_APP_GOLD_CONTRACT, goldAbi.abi, provider);
    this.goldContract = goldContract.connect(signer);
    
    goldContract.balanceOf(this.signer).then(res =>{
      this.tokenBalance = res;
    })

    const adminRole = await goldContract.ADMIN_ROLE();
    const mintRole = await goldContract.MINTER_ROLE();
    this.adminRole = await goldContract.hasRole(adminRole,this.signer)
    this.mintRole = await goldContract.hasRole(mintRole,this.signer)
    const leaseContract = new ethers.Contract(process.env.VUE_APP_LEASE_CONTRACT, leaseAbi.abi, provider);
    this.leaseContract = leaseContract.connect(signer);

    leaseContract.balanceOf(this.signer).then(res => {
      console.log(res);
      this.marginBalance = res;
    });
  },
  methods: {
    async devClaim(){
      this.nftContract.devClaim(this.signer, 1, ["ABC"]).then(res => {
        ElMessage({
          showClose: true,
          type: 'success',
          message: `${res.hash}`,
        })
      });
    },
    async ownerOf(){
      ElMessageBox.prompt('Please input your TokenID', 'Tip', {
        confirmButtonText: 'OK',
        cancelButtonText: 'Cancel'
      }).then(({ value }) => {
          this.nftContract.ownerOf(value).then(res => {
            ElMessage({
              showClose: true,
              type: 'success',
              message: `Owner is: ${res}`,
            })
            this.tokenId = value;
            this.nftOwner = res;
        }).catch(err => {
          ElMessage({
            type: 'error',
            message: err.message,
          })
        });
      }).catch(() => {
        ElMessage({
          type: 'info',
          message: 'Input canceled',
        })
      });
    },
    approve(){
      if(this.tokenId == -1){
        ElMessage({
          type: 'error',
          message: "No TokenID",
        })
        return;
      }
      this.nftContract.approve(process.env.VUE_APP_LEASE_CONTRACT, this.tokenId).then(res => {
        ElMessage({
          showClose: true,
          type: 'success',
          message: `${res.hash}`,
        })
      }).catch(err => {
        ElMessage({
          type: 'error',
          message: err.message,
        })
      });
    },
    entrustedRental(){
       if(this.tokenId == -1){
        ElMessage({
          type: 'error',
          message: "No TokenID",
        })
        return;
      }
      this.leaseContract.entrustedRental(this.tokenId, 100).then(res => {
        ElMessage({
          showClose: true,
          type: 'success',
          message: `${res.hash}`,
        })
        // this.getRentalInfo();
      }).catch(err => {
        ElMessage({
          type: 'error',
          message: err.message,
        })
      });
    },
    async getRentalInfo(){
      if(this.tokenId == -1){
        ElMessage({
          type: 'error',
          message: "No TokenID",
        })
        return;
      }
      var user = await this.leaseContract.userOf(this.tokenId)
      this.leaseContract._rentals(this.tokenId).then(res => {
        this.rentalInfo = {
          owner: res.owner,
          price: res.price,
          userOf: user,
        };
      })
    },
    async authorizeMintRole(){
      const mintRole = await this.goldContract.MINTER_ROLE();
      this.goldContract.grantRole(mintRole, this.signer).then(res => {
        ElMessage({
          showClose: true,
          type: 'success',
          message: `${res.hash}`,
        })
      }).catch(err => {
        ElMessage({
          type: 'error',
          message: err.message,
        })
      })
    },
    mintGold(){
      this.goldContract.mint(1000000000).then(res => {
        ElMessage({
          showClose: true,
          type: 'success',
          message: `${res.hash}`,
        })
      }).catch(err => {
        ElMessage({
          type: 'error',
          message: err.message,
        })
      })
    },
    goldTransfer(){
      ElMessageBox.prompt('Please input Address', 'Tip', {
        confirmButtonText: 'OK',
        cancelButtonText: 'Cancel'
      }).then(({ value }) => {
        this.goldContract.transfer(value, 10000).then(res => {
          ElMessage({
            showClose: true,
            type: 'success',
            message: `${res.hash}`,
          })
        }).catch(err => {
          ElMessage({
            type: 'error',
            message: err.message,
          })
        });
      }).catch(() => {
        ElMessage({
          type: 'info',
          message: 'Input canceled',
        })
      });
    },
    async depositToken(){
      var deadline = (parseInt(new Date().getTime()/1000)) + 600;
      var value = 1000;
      this.signMsg(value, deadline).then(res => {
        const signature = res;
        let sign = signature.substring(2, signature.length);
        let hexV = sign.substring(sign.length-2,sign.length)
        let data = {
            v: parseInt(`0x${hexV}`),
            r: `0x${sign.substring(0,64)}`,
            s: `0x${sign.substring(64,128)}`,
            sign: signature
        }
        this.leaseContract.deposit(value, deadline, data.v, data.r, data.s).then(res => {
          ElMessage({
            showClose: true,
            type: 'success',
            message: `${res.hash}`,
          })
        }).catch(error => {
            ElMessage({
            type: 'error',
            message: error,
          })
        })
      })
    },
    setMintRoleAdmin(){
      this.goldContract.setMintRoleAdmin(process.env.VUE_APP_LEASE_CONTRACT).then(res => {
        ElMessage({
          showClose: true,
          type: 'success',
          message: `${res.hash}`,
        }) 
      }).catch(error => {
        ElMessage({
          type: 'error',
          message: error,
        })
      })
    },
    leaseNFTbyPrepaid(){
      var expires = (parseInt(new Date().getTime()/1000)) + 6000;
      this.leaseContract.leaseNFTbyPrepaid(this.tokenId, expires).then(res => {
        ElMessage({
          showClose: true,
          type: 'success',
          message: `${res.hash}`,
        })
      })
    },
    async getLeaseInfo(){
      if(this.tokenId == -1){
        ElMessage({
          type: 'error',
          message: "No TokenID",
        })
        return;
      }
      const leaseInfo = await this.leaseContract._leases(this.tokenId);
      this.leaseInfo = {
        owner: leaseInfo.owner,
        expires: leaseInfo.expires,
        agreement: leaseInfo.agreement,
        user: leaseInfo.user
      }
      
      if(leaseInfo.agreement){
        console.log(leaseInfo.agreement)
        const agreementContract = new ethers.Contract(leaseInfo.agreement, agreementAbi.abi, provider);
        const signer = provider.getSigner();
        this.agreementContract = agreementContract.connect(signer);
      }
    },
    exchangeGoldToken(){
      this.agreementContract.mint(10).then(res => {
        ElMessage({
          showClose: true,
          type: 'success',
          message: `${res.hash}`,
        })
      })
    },
    async getRepaidToken(){
      if(!this.agreementContract){
        ElMessage({
          type: 'error',
          message: "No Agreement Contract",
        })
        return;
      }
      const repaid = await this.agreementContract.repaid();
      console.log(repaid);
      this.repaid = repaid;
    },
    async signMsg(value, deadline){
      var chainid = await this.goldContract.blockId();
      var nonce = await this.goldContract.nonces(this.signer);
      console.log(parseInt(nonce));
      const typedData = {
          "types": {
              "EIP712Domain": [
                  {"name": "name", "type": "string"},
                  {"name": "version", "type": "string"},
                  {"name": "chainId", "type": "uint256"},
                  {"name": "verifyingContract", "type": "address"}
              ],
              "Permit": [
                  {
                      "name": "owner",
                      "type": "address"
                  },
                  {
                      "name": "spender",
                      "type": "address"
                  },
                  {
                      "name": "value",
                      "type": "uint256"
                  },
                  {
                      "name": "nonce",
                      "type": "uint256"
                  },
                  {
                      "name": "deadline",
                      "type": "uint256"
                  }
              ]
          },
          "primaryType": "Permit",
          "domain": {
              "name": "Gold",
              "version": "1",
              "chainId": chainid.toNumber(),
              "verifyingContract": process.env.VUE_APP_GOLD_CONTRACT
          },
          "message": {
              "owner": this.signer,
              "spender": process.env.VUE_APP_LEASE_CONTRACT,
              "value": value,
              "nonce": parseInt(nonce),
              "deadline": deadline
          }
      }
      var params = [this.signer, JSON.stringify(typedData)];
      var method = 'eth_signTypedData_v4';
      var from = this.signer;
      return window.ethereum.request({method,params,from});
    }
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  padding-top: 60px;
}

.dashed {
  border-top: 2px dashed var(--el-border-color);
}
</style>
