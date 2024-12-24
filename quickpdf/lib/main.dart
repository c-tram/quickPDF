import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';

// ···
class MyCameraDelegate extends ImagePickerCameraDelegate {
  @override
  Future<XFile?> takePhoto(
      {ImagePickerCameraDelegateOptions options =
          const ImagePickerCameraDelegateOptions()}) async {
    return _takeAPhoto(options.preferredCameraDevice);
  }

  @override
  Future<XFile?> takeVideo(
      {ImagePickerCameraDelegateOptions options =
          const ImagePickerCameraDelegateOptions()}) async {
    return _takeAVideo(options.preferredCameraDevice);
  }

  Future<XFile?> _takeAPhoto(CameraDevice preferredCameraDevice) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: preferredCameraDevice == CameraDevice.front
          ? CameraDevice.front
          : CameraDevice.rear,
    );
    return photo;
  }

  Future<XFile?> _takeAVideo(CameraDevice preferredCameraDevice) async {
    // Implement your video-taking logic here
    return null;
  }
}

// ···
void setUpCameraDelegate() {
  final ImagePickerPlatform instance = ImagePickerPlatform.instance;
  if (instance is CameraDelegatingImagePickerPlatform) {
    instance.cameraDelegate = MyCameraDelegate();
  }
}

class CameraWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Widget'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                final delegate = MyCameraDelegate();
                final photo = await delegate.takePhoto();
                if (photo != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Photo taken: ${photo.path}')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No photo taken')),
                  );
                }
              },
              child: Text('Take a Photo'),
            ),
            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                try {
                  final List<XFile>? photos = await picker.pickMultiImage();
                  if (photos != null && photos.isNotEmpty) {
                    await createPdfWithPhotos(photos);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('PDF created with photos')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('No photos selected')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error picking photos: $e')),
                  );
                }
              },
              child: Text('Create PDF with Photos'),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotosPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Implement your logic to display all photos saved on the iOS device
    return Scaffold(
      appBar: AppBar(
        title: Text('Photos'),
      ),
      body: Center(
        child: FutureBuilder<List<XFile>>(
          future: _loadPhotos(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text('No photos found');
            } else {
              final photos = snapshot.data!;
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4.0,
                  mainAxisSpacing: 4.0,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return Image.file(
                    File(photos[index].path),
                    fit: BoxFit.cover,
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Future<List<XFile>> _loadPhotos() async {
    final picker = ImagePicker();
    final List<XFile>? photos = await picker.pickMultiImage();
    return photos ?? [];
  }
}

void main() {
  runApp(MaterialApp(
    home: CameraWidget(),
  ));
}

Future<void> createPdfWithPhotos(List<XFile> photos) async {
  final pdf = pw.Document();

  for (var photo in photos) {
    final image = pw.MemoryImage(
      await File(photo.path).readAsBytes(),
    );

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(
              image,
            ),
          );
        },
      ),
    );
  }

  final output = await getTemporaryDirectory();
  final file = File("${output.path}/photos.pdf");
  await file.writeAsBytes(await pdf.save());

  // Code to share the PDF file to the Files app
  // This requires the `share` package
  Share.shareFiles([file.path], mimeTypes: ['application/pdf']);
}
