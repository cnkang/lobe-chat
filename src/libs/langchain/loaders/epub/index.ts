import { RecursiveCharacterTextSplitter } from 'langchain/text_splitter';

import { TempFileManager } from '@/server/utils/tempFileManager';
import { nanoid } from '@/utils/uuid';

import { loaderConfig } from '../config';

export const EPubLoader = async (content: Uint8Array) => {
  // Check if EPUB support is disabled
  if (process.env.NEXT_PUBLIC_ENABLE_LANGCHAIN_EPUB === 'false') {
    throw new Error('EPUB support is disabled in this build');
  }

  const tempManager = new TempFileManager('epub-');

  try {
    // Dynamic import to avoid build issues
    const { EPubLoader: Loader } = await import('@langchain/community/document_loaders/fs/epub');
    
    const tempPath = await tempManager.writeTempFile(content, `${nanoid()}.epub`);
    const loader = new Loader(tempPath);
    const documents = await loader.load();

    const splitter = new RecursiveCharacterTextSplitter(loaderConfig);
    return await splitter.splitDocuments(documents);
  } catch (e) {
    throw new Error(`EPubLoader error: ${(e as Error).message}`);
  } finally {
    tempManager.cleanup(); // 确保清理
  }
};
