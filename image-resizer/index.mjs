import sharp from 'sharp';
import { S3Client, GetObjectCommand, PutObjectCommand } from '@aws-sdk/client-s3';

const s3 = new S3Client({});

/**
 * AWS Lambda handler for automated S3 image resizing.
 * Triggered when a new image is uploaded to S3.
 */
export const handler = async (event) => {
  try {
    const record = event.Records?.[0]?.s3;
    if (!record) {
      throw new Error('Invalid event record: missing S3 payload structure');
    }

    const bucket = record.bucket.name;
    const key = decodeURIComponent(record.object.key.replace(/\+/g, ' '));

    console.log(`[INFO] Processing image from bucket: ${bucket}, key: ${key}`);

    // Safeguard against processing non-original files or infinite loops
    if (key.startsWith('resized/')) {
      console.log(`[SKIP] Skipping already resized image: ${key}`);
      return { statusCode: 200, body: 'Skipped resized object' };
    }

    // 1. Retrieve the original image from S3
    const original = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
    const buffer = await original.Body.transformToBuffer();

    // 2. Resize image using sharp
    const resizedBuffer = await sharp(buffer)
      .resize(200, 200, { fit: 'inside', withoutEnlargement: true })
      .toBuffer();

    // 3. Determine output key and content-type
    const resizedKey = key.includes('originals/')
      ? key.replace('originals/', 'resized/')
      : `resized/${key}`;

    const contentType = original.ContentType || 'image/jpeg';

    // 4. Upload resized image to S3
    await s3.send(new PutObjectCommand({
      Bucket: bucket,
      Key: resizedKey,
      Body: resizedBuffer,
      ContentType: contentType,
      Metadata: {
        'resized-by': 'image-resizer-lambda',
        'original-key': key,
      },
    }));

    console.log(`[SUCCESS] Resized s3://${bucket}/${key} -> s3://${bucket}/${resizedKey}`);
    return {
      statusCode: 200,
      body: JSON.stringify({ message: `Resized ${key} -> ${resizedKey}` }),
    };
  } catch (error) {
    console.error(`[ERROR] Image resize failed for event:`, JSON.stringify(event), error);
    throw error;
  }
};