# Twin: Inheritance

* representer_class is inheritable_attr
* in inherited class, superclass.representer_class.clone is called
* this will call clone on Config, which clones every property. (how does nested cloning work, again?)