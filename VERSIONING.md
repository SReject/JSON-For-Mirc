# Versioning
> This project uses a version schema formatted as:
> > `a.b.cddd`  

### Major Version (`a`)   
> Only increased when the current project's code base is incompatible with a previous major version  
>
> Newly added features will not cause a major version increase but significate behavior changes will  

### Minor Version (`b`)  
> Only increased at the start of a developement cycle  

### Developement Cycle State(`c`)  
> Indicates where in the developement cycle the current code base is.  
> Some states may be skipped if deemed unnecessary.  
>
> **`0`: In dev**  
> > The project's code is incomplete and non-functional  
>
> **`1`: Alpha**  
> > The project's code is incomplete and has desired features missing.  
> > The project's code is mostly functional but may have significant amounts of bugs.  
>
> **`2`: Beta**  
> > The project's code is complete but desired features may still be missing.  
> > The project's code is functional but may have significant amounts of bugs.  
>
> **`3`: Release Candidate**  
> > The project's code is complete and all desired features have been added. 
> > The project's code is functional but may contain minor amounts of bugs.
>
> **`4`-`9`: Stable Release**  
> > The project's code is complete and all desired features have been added.  
> > The project's code is functional and should not contain bugs.  

### Build(`ddd`)
> Incremented often as changes are made to the project's code.
