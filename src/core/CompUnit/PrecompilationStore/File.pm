class CompUnit::PrecompilationStore::File does CompUnit::PrecompilationStore {
    has IO::Path $.prefix is required;
    has IO::Handle $!lock;

    submethod BUILD(IO::Path :$!prefix) {
        $!prefix.mkdir;
    }

    method !dir(CompUnit::PrecompilationId $compiler-id,
                CompUnit::PrecompilationId $precomp-id)
    {
        self.prefix
            .child($compiler-id.IO)
            .child($precomp-id.substr(0, 2).IO)
    }

    method path(CompUnit::PrecompilationId $compiler-id,
                 CompUnit::PrecompilationId $precomp-id)
    {
        self!dir($compiler-id, $precomp-id).child($precomp-id.IO)
    }

    method !lock(Int:D $mode) {
        return if $*W && $*W.is_precompilation_mode();
        $!lock //= $.prefix.child('.lock').open(:create, :rw);
        $!lock.lock($mode);
    }

    method unlock() {
        $!lock ?? $!lock.unlock !! True;
    }

    method load(CompUnit::PrecompilationId $compiler-id,
                CompUnit::PrecompilationId $precomp-id)
    {
        my $path = self.path($compiler-id, $precomp-id);
        if $path ~~ :e {
            self!lock(1);
            $path
        }
        else {
             IO::Path
        }
    }

    method destination(CompUnit::PrecompilationId $compiler-id,
                       CompUnit::PrecompilationId $precomp-id)
        returns IO::Path
    {
        self!lock(2);
        my $compiler-dir = self.prefix.child($compiler-id.IO);
        $compiler-dir.mkdir unless $compiler-dir.e;
        my $dest = self!dir($compiler-id, $precomp-id);
        $dest.mkdir unless $dest.e;
        $dest.child($precomp-id.IO)
    }

    method store(CompUnit::PrecompilationId $compiler-id,
                 CompUnit::PrecompilationId $precomp-id,
                 IO::Path:D $path)
    {
        $path.copy(self.destination($compiler-id, $precomp-id));
        self.unlock;
    }

    method delete(CompUnit::PrecompilationId $compiler-id, CompUnit::PrecompilationId $precomp-id)
    {
        self.path($compiler-id, $precomp-id).unlink;
    }

    method delete-by-compiler(CompUnit::PrecompilationId $compiler-id)
    {
         my $compiler-dir = self.prefix.child($compiler-id.IO);
         for $compiler-dir.dir -> $subdir {
             $subdir.dir>>.unlink;
             $subdir.rmdir;
         }
         $compiler-dir.rmdir;
    }
}

# vim: ft=perl6 expandtab sw=4
