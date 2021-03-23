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
            y: publicKey.Q.y.toString(),
            string: publickeyString
        },
        signature: {
            r: signatureObj.r.toString(),
            s: signatureObj.s.toString()
        }
    }
}
const accountToPublicKey = (account) => {
    const eos = EosApi(options)
    async function fetchAccounInfo() {
        try {
            return { ok: await eos.getAccount(account) }
        } catch (error) {
            return { error: "error fetching account" };
        }
    }

    return (async function () {
        return await fetchAccounInfo();
    })();
}
const generateKeys = () => {
    async function getKeys() {
        return ecc.randomKey().then(privateKey => ({
            privateKey: privateKey,
            publicKey: ecc.privateToPublic(privateKey)
        }))
    }

    return (async function () {
        return await getKeys();
    })();
}
const sign = (phrase) => {
    return ecc.randomKey().then(privateKey => {
        let publicKey = ecc.privateToPublic(privateKey)
        let signature = ecc.sign(JSON.stringify(phrase), privateKey)
        return {
            signature: signature,
            privateKey: privateKey,
            publicKey: publicKey
        }
    })
}

exports.publicKeyPoints = publicKeyPoints
exports.accountToPublicKey = accountToPublicKey
exports.sign = sign
