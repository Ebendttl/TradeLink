import { openContractCall } from '@stacks/connect';
import { 
  callReadOnlyFunction, 
  cvToJSON, 
  stringAsciiCV,
  principalCV 
} from '@stacks/transactions';
import { StacksMocknet } from '@stacks/network';

const network = new StacksMocknet();
const DEPLOYER_ADDRESS = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
const REGISTRY_CONTRACT = 'contract-registry';

export const getContractFromRegistry = async (name: string): Promise<string | null> => {
  try {
    const result = await callReadOnlyFunction({
      contractAddress: DEPLOYER_ADDRESS,
      contractName: REGISTRY_CONTRACT,
      functionName: 'get-contract-address',
      functionArgs: [stringAsciiCV(name)],
      network,
      senderAddress: DEPLOYER_ADDRESS,
    });
    
    const jsonResult = cvToJSON(result);
    return jsonResult.value?.value || null;
  } catch (error) {
    console.error(`Error fetching contract ${name} from registry:`, error);
    return null;
  }
};

export const protocolContracts = {
  registry: `${DEPLOYER_ADDRESS}.${REGISTRY_CONTRACT}`,
  get: async (name: string) => {
    const addr = await getContractFromRegistry(name);
    return addr || `${DEPLOYER_ADDRESS}.${name}`; // Fallback if registry fails
  }
};
