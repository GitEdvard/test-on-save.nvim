using Xunit;
using edvard;
namespace tests;
public class UnitTest1
{
    [Fact]
    public void Test1()
    {
        Assert.False(false);
    }
    public void Test2()
    {
        Person person = new Person();
        person.Register("edvard", "myaddress");
        Assert.Same(person.Name, "y");
    }
}

