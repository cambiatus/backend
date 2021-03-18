import ecc, { PublicKey, Signature } from 'eosjs-ecc'
import EosApi from 'eosjs-api'

const options = {
    httpEndpoint: 'https://staging.cambiatus.io',
    verbose: false
}
const eos = EosApi(options)

const publicKeyPoints = (signature, message) => {
    let signatureObj = Signature.from(signature)
    let publickeyString = ecc.recover(signature, message)
    let publicKey = PublicKey(publickeyString)

    return {
        publicKey: {
            x: publicKey.Q.x.toString(),
            y: publicKey.Q.y.toString()
        },
        signature: {
            r: signatureObj.r.toString(),
            s: signatureObj.s.toString()
        }
    }
}
const accountToPublicKey = (account) => {
    const eos = EosApi(options)
    async function getAccounInfo() {
        try {
            return await eos.getAccount(account)
        } catch (error) {
            return { error: "error fetching account" };
        }
    }

    return (async function () {
        return await getAccounInfo();
    })();
}

exports.publicKeyPoints = publicKeyPoints
exports.accountToPublicKey = accountToPublicKey
