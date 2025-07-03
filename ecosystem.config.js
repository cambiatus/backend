module.exports = {
  apps: [
    {
      name: 'cambiatus-backend',
      script: './start.sh',
      interpreter: '/bin/bash',
      cwd: '/opt/cambiatus/backend',
      
      // Environment variables for production
      env: {
        NODE_ENV: 'production',
        MIX_ENV: 'prod',
        PHX_SERVER: 'true',
        PORT: '4000',
        
        // Required environment variables that must be set on the server
        // DATABASE_URL: 'ecto://user:pass@host/database',
        // SECRET_KEY_BASE: 'your-secret-key-base',
        // PHX_HOST: 'your-domain.com',
        
        // EOS/Blockchain configuration
        // EOSIO_WALLET_NAME: 'default',
        // BESPIRAL_WALLET_PASSWORD: 'your-wallet-password',
        // BESPIRAL_ACCOUNT: 'your-eos-account',
        // BESPIRAL_CONTRACT: 'your-contract',
        // BESPIRAL_AUTO_INVITE_CMM: 'your-cmm',
        // EOSIO_WALLET_URL: 'http://localhost:8888',
        // EOSIO_URL: 'http://localhost:8888',
        // EOSIO_SYMBOL: 'EOS',
        
        // Auth configuration
        // GRAPHQL_SECRET: 'your-graphql-secret',
        // USER_SALT: 'your-user-salt',
        // EMAIL_SALT: 'your-email-salt',
        // INVITATION_SALT: 'your-invitation-salt',
        
        // AWS SES configuration
        // AWS_SES_REGION: 'us-east-1',
        // AWS_SES_ACCESS_KEY: 'your-access-key',
        // AWS_SES_SECRET_ACCESS_KEY: 'your-secret-access-key',
        
        // Sentry configuration
        // SENTRY_DSN: 'your-sentry-dsn',
        
        // Push notifications
        // PUSH_PUBLIC_KEY: 'your-push-public-key',
        // PUSH_PRIVATE_KEY: 'your-push-private-key'
      },
      
      // PM2 options
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      
      // Logging
      log_file: '/var/log/cambiatus/combined.log',
      out_file: '/var/log/cambiatus/out.log',
      error_file: '/var/log/cambiatus/error.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      
      // Health check
      min_uptime: '10s',
      max_restarts: 10
    }
  ]
};
