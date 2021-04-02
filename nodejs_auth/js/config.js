const development = {
    eosOptions: {
        httpEndpoint: 'https://staging.cambiatus.io'
    },
}

const production = {
    eosOptions: {
        httpEndpoint: process.env.EOS_ENDPOINT
    },
}

export default {
    development,
    production
}
