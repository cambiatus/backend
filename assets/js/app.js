import ecc, { PublicKey, Signature } from 'eosjs-ecc'

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

exports.publicKeyPoints = publicKeyPoints
