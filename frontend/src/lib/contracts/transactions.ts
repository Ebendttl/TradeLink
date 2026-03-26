import { openContractCall } from '@stacks/connect';
import { toast } from 'sonner';

interface TxOptions {
  contractAddress: string;
  contractName: string;
  functionName: string;
  functionArgs: any[];
  postConditions?: any[];
  onFinish?: (data: any) => void;
  onCancel?: () => void;
}

export const executeContractCall = async (options: TxOptions) => {
  const { contractAddress, contractName, functionName, functionArgs, onFinish, onCancel } = options;

  console.log(`Executing contract call ${contractName}.${functionName}`);
  
  await openContractCall({
    contractAddress,
    contractName,
    functionName,
    functionArgs,
    onFinish: (data) => {
      console.log('Transaction signed:', data);
      toast.success('Transaction submitted successfully!');
      if (onFinish) onFinish(data);
    },
    onCancel: () => {
      console.log('Transaction cancelled');
      toast.error('Transaction cancelled');
      if (onCancel) onCancel();
    },
  });
};
