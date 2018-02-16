# shrine-ftp
Shrine storage that handles file uploads to an FTP server

## Usage
Refer to the Shrine [Quick start](http://shrinerb.com/rdoc/files/README_md.html#label-Quick+start) if you need to
know how to set up storage in the first place.

```
require "shrine"
require "shrine/storage/file_system"
require "shrine-ftp"

storage = Shrine::Storage::Ftp.new(
    host: 'ftp.yourhost.com',
    user: 'ftp_user',
    passwd: 'ftp_password',
    dir: 'your/path/to/files',
    prefix: 'http://cdn.yourhost.com'
)

Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new('public', prefix: 'uploads/cache'),
    store: storage
}
```