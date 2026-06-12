package com.medicare.entity;

public class Manufacturer {
    private int manufacturerId;
    private String name;
    private String country;
    private String address;

    public Manufacturer() {}

    public Manufacturer(int manufacturerId, String name, String country, String address) {
        this.manufacturerId = manufacturerId;
        this.name = name;
        this.country = country;
        this.address = address;
    }

    public int getManufacturerId() { return manufacturerId; }
    public void setManufacturerId(int manufacturerId) { this.manufacturerId = manufacturerId; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
}