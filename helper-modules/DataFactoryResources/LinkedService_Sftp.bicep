// ============================================================================
// Data Factory Linked Service – SFTP
// Connects Data Factory to an SFTP server for file-based integrations.
// Supports Basic (password) and SSH Public Key authentication.
// ============================================================================

// ============================================================================
// Parameters
// ============================================================================

@description('Required. Name of the existing Data Factory instance.')
param dataFactoryName string

@description('Required. Name of the linked service to create.')
param linkedServiceName string

@description('Required. SFTP linked service configuration.')
param sftpSettings {
  @description('Required. Hostname or IP address of the SFTP server.')
  host: string

  @description('Optional. Port number. Defaults to 22.')
  port: int?

  @description('Optional. Authentication type. Defaults to Basic.')
  authenticationType: ('Basic' | 'SshPublicKey' | 'MultiFactor')?

  @description('Required. User name for authentication.')
  userName: string

  @description('Conditional. Azure Key Vault secret reference for the password. Required when authenticationType is Basic.')
  passwordKeyVaultReference: {
    @description('Required. Name of the Key Vault linked service.')
    linkedServiceName: string
    @description('Required. Name of the secret in Key Vault.')
    secretName: string
    @description('Optional. Version of the secret.')
    secretVersion: string?
  }?

  @description('Conditional. Azure Key Vault secret reference for the SSH private key. Required when authenticationType is SshPublicKey.')
  privateKeyKeyVaultReference: {
    @description('Required. Name of the Key Vault linked service.')
    linkedServiceName: string
    @description('Required. Name of the secret in Key Vault.')
    secretName: string
    @description('Optional. Version of the secret.')
    secretVersion: string?
  }?

  @description('Conditional. Azure Key Vault secret reference for the SSH private key passphrase. Optional when authenticationType is SshPublicKey.')
  passphraseKeyVaultReference: {
    @description('Required. Name of the Key Vault linked service.')
    linkedServiceName: string
    @description('Required. Name of the secret in Key Vault.')
    secretName: string
    @description('Optional. Version of the secret.')
    secretVersion: string?
  }?

  @description('Optional. SSH host key fingerprint for server verification (e.g. ssh-rsa 2048 xx:xx:xx:...).')
  hostKeyFingerprint: string?

  @description('Optional. Skip host key validation. Defaults to false. Set to true only for testing.')
  skipHostKeyValidation: bool?

  @description('Optional. Description of the linked service.')
  description: string?
}

// ============================================================================
// Variables
// ============================================================================

var authType = sftpSettings.?authenticationType ?? 'Basic'

var passwordRef = sftpSettings.?passwordKeyVaultReference != null
  ? {
      type: 'AzureKeyVaultSecret'
      store: {
        referenceName: sftpSettings.passwordKeyVaultReference!.linkedServiceName
        type: 'LinkedServiceReference'
      }
      secretName: sftpSettings.passwordKeyVaultReference!.secretName
      secretVersion: sftpSettings.passwordKeyVaultReference!.?secretVersion
    }
  : null

var privateKeyRef = sftpSettings.?privateKeyKeyVaultReference != null
  ? {
      type: 'AzureKeyVaultSecret'
      store: {
        referenceName: sftpSettings.privateKeyKeyVaultReference!.linkedServiceName
        type: 'LinkedServiceReference'
      }
      secretName: sftpSettings.privateKeyKeyVaultReference!.secretName
      secretVersion: sftpSettings.privateKeyKeyVaultReference!.?secretVersion
    }
  : null

var passphraseRef = sftpSettings.?passphraseKeyVaultReference != null
  ? {
      type: 'AzureKeyVaultSecret'
      store: {
        referenceName: sftpSettings.passphraseKeyVaultReference!.linkedServiceName
        type: 'LinkedServiceReference'
      }
      secretName: sftpSettings.passphraseKeyVaultReference!.secretName
      secretVersion: sftpSettings.passphraseKeyVaultReference!.?secretVersion
    }
  : null

var baseTypeProperties = {
  host: sftpSettings.host
  port: sftpSettings.?port ?? 22
  authenticationType: authType
  userName: sftpSettings.userName
  skipHostKeyValidation: sftpSettings.?skipHostKeyValidation ?? false
  hostKeyFingerprint: sftpSettings.?hostKeyFingerprint
}

var basicAuthProperties = authType == 'Basic'
  ? {
      password: passwordRef
    }
  : {}

var sshKeyAuthProperties = authType == 'SshPublicKey'
  ? {
      privateKeyContent: privateKeyRef
      passPhrase: passphraseRef
    }
  : {}

var typeProperties = union(baseTypeProperties, basicAuthProperties, sshKeyAuthProperties)

// ============================================================================
// Resources
// ============================================================================

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
}

resource linkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  parent: dataFactory
  name: linkedServiceName
  properties: {
    type: 'Sftp'
    description: sftpSettings.?description ?? 'SFTP linked service'
    typeProperties: typeProperties
  }
}
